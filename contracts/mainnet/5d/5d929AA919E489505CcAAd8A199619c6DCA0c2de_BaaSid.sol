pragma solidity ^0.5.4;

import "./ercInterface.sol";

contract BaaSid is ERC20, Ownable, Pausable {

    using SafeMath for uint256;

    struct LockupInfo {
        uint256 releaseTime;
        uint256 lockupBalance;
        
    }

    string public name;
    string public symbol;
    uint8 constant public decimals =18;
    uint256 internal initialSupply;
    uint256 internal totalSupply_;
    uint256 internal mintCap;

    mapping(address => uint256) internal balances;
    mapping(address => bool) internal locks;
    mapping(address => bool) public frozen;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => LockupInfo[]) internal lockupInfo;
    
    address implementation;

    event Lock(address indexed holder, uint256 value);
    event Unlock(address indexed holder, uint256 value);
    event Burn(address indexed owner, uint256 value);
    event Mint(uint256 value);
    event Freeze(address indexed holder);
    event Unfreeze(address indexed holder);

    modifier notFrozen(address _holder) {
        require(!frozen[_holder]);
        _;
    }

    constructor() public {
        name = "BaaSid";
        symbol = "BAAS";
        initialSupply = 10000000000;
        totalSupply_ = initialSupply * 10 ** uint(decimals);
        mintCap = 10000000000 * 10 ** uint(decimals);
        balances[owner] = totalSupply_;

        emit Transfer(address(0), owner, totalSupply_);
    }

    function () payable external {
        address impl = implementation;
        require(impl != address(0));
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
    function _setImplementation(address _newImp) internal {
        implementation = _newImp;
    }
    
    function upgradeTo(address _newImplementation) public onlyOwner {
        require(implementation != _newImplementation);
        _setImplementation(_newImplementation);
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused notFrozen(msg.sender) returns (bool) {
        if (locks[msg.sender]) {
            autoUnlock(msg.sender);
        }
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
     function multiTransfer(address[] memory _toList, uint256[] memory _valueList) public whenNotPaused notFrozen(msg.sender) returns(bool){
        if(_toList.length != _valueList.length){
            revert();
        }
        
        for(uint256 i = 0; i < _toList.length; i++){
            transfer(_toList[i], _valueList[i]);
        }
        
        return true;
    }
    
   
    function balanceOf(address _holder) public view returns (uint256 balance) {
        uint256 lockedBalance = 0;
        if(locks[_holder]) {
            for(uint256 idx = 0; idx < lockupInfo[_holder].length ; idx++ ) {
                lockedBalance = lockedBalance.add(lockupInfo[_holder][idx].lockupBalance);
            }
        }
        return balances[_holder] + lockedBalance;
    }
    
    function currentBalanceOf(address _holder) public view returns(uint256 balance){
        uint256 unlockedBalance = 0;
        if(locks[_holder]){
            for(uint256 idx =0; idx < lockupInfo[_holder].length; idx++){
                if( lockupInfo[_holder][idx].releaseTime <= now){
                    unlockedBalance = unlockedBalance.add(lockupInfo[_holder][idx].lockupBalance);
                }
            }
        }
        return balances[_holder] + unlockedBalance;
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused notFrozen(_from)returns (bool) {
        if (locks[_from]) {
            autoUnlock(_from);
        }
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = (allowed[msg.sender][spender].add(addedValue));

        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance( address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = (allowed[msg.sender][spender].sub(subtractedValue));

        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function allowance(address _holder, address _spender) public view returns (uint256) {
        return allowed[_holder][_spender];
    }

    function lock(address _holder, uint256 _releaseStart, uint256 _amount) public onlyOwner returns(bool){
        require(balances[_holder] >= _amount);
        balances[_holder] = balances[_holder].sub(_amount);
        
        lockupInfo[_holder].push(
            LockupInfo(_releaseStart, _amount)    
        );
        
        locks[_holder] = true;
        
        emit Lock(_holder, _amount);
        
        return true;
        
    }

    function _unlock(address _holder, uint256 _idx) internal returns (bool) {
        require(locks[_holder]);
        require(_idx < lockupInfo[_holder].length);
        LockupInfo storage lockupinfo = lockupInfo[_holder][_idx];
        uint256 releaseAmount = lockupinfo.lockupBalance;
        
        delete lockupInfo[_holder][_idx];
        
        lockupInfo[_holder][_idx] = lockupInfo[_holder][lockupInfo[_holder].length.sub(1)];
        
        lockupInfo[_holder].length -= 1;
        
        if(lockupInfo[_holder].length == 0){
            locks[_holder] = false;
        }
        
        emit Unlock(_holder, releaseAmount);
        balances[_holder] = balances[_holder].add(releaseAmount);
        
        return true;
    }

    function unlock(address _holder, uint256 _idx) public onlyOwner returns (bool) {
        _unlock(_holder, _idx);
    }

    function freezeAccount(address _holder) public onlyOwner returns (bool) {
        require(!frozen[_holder]);
        frozen[_holder] = true;
        emit Freeze(_holder);
        return true;
    }

    function unfreezeAccount(address _holder) public onlyOwner returns (bool) {
        require(frozen[_holder]);
        frozen[_holder] = false;
        emit Unfreeze(_holder);
        return true;
    }

    function getNowTime() public view returns(uint256) {
        return now;
    }

    function showLockState(address _holder, uint256 _idx) public view returns (bool, uint256, uint256, uint256) {
        if(locks[_holder]) {
            return (
                locks[_holder],
                lockupInfo[_holder].length,
                lockupInfo[_holder][_idx].releaseTime,
                lockupInfo[_holder][_idx].lockupBalance
            );
        } else {
            return (
                locks[_holder],
                lockupInfo[_holder].length,
                0,0
            );

        }
    }
    
  
    function distribute(address _to, uint256 _value) public onlyOwner returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

   
    
    function claimToken(ERC20 token, address _to, uint256 _value) public onlyOwner returns (bool) {
        token.transfer(_to, _value);
        return true;
    }

    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
        return true;
    }
    
    function burnFrom(address account, uint256 _value) public returns (bool) {
        uint256 decreasedAllowance = allowance(account, msg.sender).sub(_value);

        approve(msg.sender, decreasedAllowance);
        burn(_value);
    }
   
 
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        require(mintCap >= totalSupply_.add(_amount));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     function autoUnlock(address _holder) internal returns(bool){
        if(locks[_holder] == false){
            return true;
        }
        
        for(uint256 idx = 0; idx < lockupInfo[_holder].length; idx++){
            if(lockupInfo[_holder][idx].releaseTime <= now)
            {
                if(_unlock(_holder, idx)){
                    idx -= 1;
                }
            }
        }
        return true;
    }
}