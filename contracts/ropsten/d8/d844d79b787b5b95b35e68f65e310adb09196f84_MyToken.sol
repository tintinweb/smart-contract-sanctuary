pragma solidity ^0.4.18;

contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event TransferSell(address indexed from, uint tokens, uint eth);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract MyToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public totalSupply;
    uint public sellRate;
    uint public buyRate;
    
    struct lockPosition1{
        uint8 typ; // 1 2 3 4
        uint count;
        uint time1;
        uint8 releaseRate1;
        uint time2;
        uint8 releaseRate2;
        uint time3;
        uint8 releaseRate3;
        uint time4;
        uint8 releaseRate4;
    }
    
    struct supplierContract{
        uint _code;
        uint8 _typ;
        uint8 _state; // 0 1 2 3 4 5
        uint _add_time;
        uint _end_time;
        uint _count;
        address _from;
        address _to0;
        address _to1;
        address _to2;
        address _to3;
        address _sup;
    }
    
    mapping(address => lockPosition1) public lposition1;
    
    mapping(address => uint) public lockSupplier;
    
    mapping(uint => supplierContract) public supplierContractInfo;
    mapping(address => uint) public supplierCount;
    
    
    mapping (address => bool) public lockedAccounts;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    modifier is_not_locked(address _address) {
        if (lockedAccounts[_address] == true) revert();
        _;
    }
    
    modifier validate_address(address _address) {
        if (_address == address(0)) revert();
        _;
    }
    
    modifier is_locked(address _address) {
        if (lockedAccounts[_address] != true) revert();
        _;
    }
    
    modifier validate_position(address _address,uint count) {
        if(balances[_address] < count) revert();
        if(lposition1[_address].count == 0 && safeSub(balances[_address],count) < lockSupplier[_address]) revert();
        if(lposition1[_address].count > 0 && safeSub(balances[_address],count) < lposition1[_address].count && now < lposition1[_address].time1) revert();
        checkPosition1(_address,count);
        _;
    }
    
    function checkPosition1(address _address,uint count) private view {
        if(lposition1[_address].releaseRate1 < 100 && lposition1[_address].count > 0){
            uint _tmpRateAll = 0;
            
            if(lposition1[_address].typ == 2 && now < lposition1[_address].time2){
                if(now >= lposition1[_address].time1){
                    _tmpRateAll = lposition1[_address].releaseRate1;
                }
            }
            
            if(lposition1[_address].typ == 3 && now < lposition1[_address].time3){
                if(now >= lposition1[_address].time1){
                    _tmpRateAll = lposition1[_address].releaseRate1;
                }
                if(now >= lposition1[_address].time2){
                    _tmpRateAll = safeAdd(lposition1[_address].releaseRate2,_tmpRateAll);
                }
            }
            
            if(lposition1[_address].typ == 4 && now < lposition1[_address].time4){
                if(now >= lposition1[_address].time1){
                    _tmpRateAll = lposition1[_address].releaseRate1;
                }
                if(now >= lposition1[_address].time2){
                    _tmpRateAll = safeAdd(lposition1[_address].releaseRate2,_tmpRateAll);
                }
                if(now >= lposition1[_address].time3){
                    _tmpRateAll = safeAdd(lposition1[_address].releaseRate3,_tmpRateAll);
                }
            }
            
            uint _tmp1 = safeSub(balances[_address],count);
            uint _tmp2 = safeSub(lposition1[_address].count,safeDiv(lposition1[_address].count*_tmpRateAll,100));
            
            if(_tmpRateAll > 0){
                if(_tmp1 < _tmp2) revert();
            }
        }
    }
    
    event _lockAccount(address _add);
    event _unlockAccount(address _add);
    
    function () public payable{
        require(owner != msg.sender);
        require(buyRate > 0);
        
        require(msg.value >= 0.1 ether && msg.value <= 1000 ether);
        uint tokens;
        
        tokens = msg.value / (1 ether * 1 wei / buyRate);
        
        
        require(balances[owner] >= tokens * 10**uint(decimals));
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens * 10**uint(decimals));
        balances[owner] = safeSub(balances[owner], tokens * 10**uint(decimals));
    }

    function MyToken(uint _sellRate,uint _buyRate,string _symbol,string _name) public payable {
        require(_sellRate >0 && _buyRate > 0);
        symbol = _symbol;
        name = _name;
        decimals = 8;
        totalSupply = 2000000000 * 10**uint(decimals);
        balances[owner] = totalSupply;
        Transfer(address(0), owner, totalSupply);
        sellRate = _sellRate;
        buyRate = _buyRate;
    }

    function totalSupply() public constant returns (uint) {
        return totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public is_not_locked(msg.sender) is_not_locked(to) validate_position(msg.sender,tokens) returns (bool success) {
        require(to != msg.sender);
        require(tokens > 0);
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public is_not_locked(msg.sender) is_not_locked(spender) validate_position(msg.sender,tokens) returns (bool success) {
        require(spender != msg.sender);
        require(tokens > 0);
        require(balances[msg.sender] >= tokens);
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public is_not_locked(msg.sender) is_not_locked(from) is_not_locked(to) validate_position(from,tokens) returns (bool success) {
        require(transferFromCheck(from,to,tokens));
        return true;
    }
    
    function transferFromCheck(address from,address to,uint tokens) private returns (bool success) {
        require(tokens > 0);
        require(from != msg.sender && msg.sender != to && from != to);
        require(balances[from] >= tokens && allowed[from][msg.sender] >= tokens);
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    

    function sellCoin(address seller, uint amount) public onlyOwner is_not_locked(seller) validate_position(seller,amount* 10**uint(decimals)) {
        require(balances[seller] >= amount * 10**uint(decimals) && amount * 10**uint(decimals) > 0);
        require(sellRate > 0);
        require(seller != msg.sender);
        uint tmpAmount = amount * (1 ether * 1 wei / sellRate);
        
        balances[owner] += amount * 10**uint(decimals);
        balances[seller] -= amount * 10**uint(decimals);
        
        seller.transfer(tmpAmount);
        TransferSell(seller, amount * 10**uint(decimals), tmpAmount);
    }
    
    // set rate
    function setRate(uint _buyRate,uint _sellRate) public onlyOwner {
        require(_buyRate > 0);
        require(_sellRate > 0);
        require(_buyRate < _sellRate);
        buyRate = _buyRate;
        sellRate = _sellRate;
    }
    
    // lockAccount
    function lockStatus(address _owner) public is_not_locked(_owner)  validate_address(_owner) onlyOwner {
        lockedAccounts[_owner] = true;
        _lockAccount(_owner);
    }

    function unlockStatus(address _owner) public is_locked(_owner) validate_address(_owner) onlyOwner {
        lockedAccounts[_owner] = false;
        _unlockAccount(_owner);
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    //set lock position
    function setLockPostion1(address _add,uint _count,uint8 _typ,uint _time1,uint8 _releaseRate1,uint _time2,uint8 _releaseRate2,uint _time3,uint8 _releaseRate3,uint _time4,uint8 _releaseRate4) public is_not_locked(_add) onlyOwner {
        require(supplierCount[_add] == 0);
        require(_count > 0);
        require(_time1 > now);
        require(_releaseRate1 > 0);
        require(_typ >= 1 && _typ <= 4);
        require(balances[_add] >= _count * 10**uint(decimals));
        require(safeAdd(safeAdd(_releaseRate1,_releaseRate2),safeAdd(_releaseRate3,_releaseRate4)) == 100);
        
        if(_typ == 1){
            require(_time2 == 0 && _releaseRate2 == 0 && _time3 == 0 && _releaseRate3 == 0);
        }
        if(_typ == 2){
            require(_time2 > _time1 && _releaseRate2 > 0 && _time3 == 0 && _releaseRate3 == 0);
        }
        if(_typ == 3){
            require(_time2 > _time1 && _releaseRate2 > 0 && _time3 > _time2 && _releaseRate3 > 0);
        }
        if(_typ == 4){
            require(_time2 > _time1 && _releaseRate2 > 0 && _releaseRate3 > 0 && _time3 > _time2 && _time4 > _time3 && _releaseRate4 > 0);
        }
        
        lockPostion1Add(_typ,_add,_count,_time1,_releaseRate1,_time2,_releaseRate2,_time3,_releaseRate3,_time4,_releaseRate4);
    }
    
    function lockPostion1Add(uint8 _typ,address _add,uint _count,uint _time1,uint8 _releaseRate1,uint _time2,uint8 _releaseRate2,uint _time3,uint8 _releaseRate3,uint _time4,uint8 _releaseRate4) private {
        lposition1[_add].typ = _typ;
        lposition1[_add].count = _count * 10**uint(decimals);
        lposition1[_add].time1 = _time1;
        lposition1[_add].releaseRate1 = _releaseRate1;
        lposition1[_add].time2 = _time2;
        lposition1[_add].releaseRate2 = _releaseRate2;
        lposition1[_add].time3 = _time3;
        lposition1[_add].releaseRate3 = _releaseRate3;
        lposition1[_add].time4 = _time4;
        lposition1[_add].releaseRate4 = _releaseRate4;
    }
    
    // create Contract
    function createContract(uint _code,uint8 _type,uint _endTime,uint _count,address _to0,address _to1,address _to2,address _to3,address _sup) public is_not_locked(msg.sender)  returns (bool success){
        require(_type >= 1 && _type <= 5);
        require(_endTime > now);
        require(lposition1[msg.sender].count == 0);
        require(_count > 0);
        require(_code != 0);
        require(supplierContractInfo[_code]._code == 0);
        require(balances[msg.sender] >= safeAdd(lockSupplier[msg.sender],_count));
        
        supplierContractInfo[_code]._code = _code;
        supplierContractInfo[_code]._from = msg.sender;
        supplierContractInfo[_code]._typ = _type;
        supplierContractInfo[_code]._state = 0;
        supplierContractInfo[_code]._add_time = now;
        supplierContractInfo[_code]._end_time = _endTime;
        supplierContractInfo[_code]._count = _count;
        supplierContractInfo[_code]._to0 = _to0;
        supplierContractInfo[_code]._to1 = _to1;
        supplierContractInfo[_code]._to2 = _to2;
        supplierContractInfo[_code]._to3 = _to3;
        supplierContractInfo[_code]._sup = _sup;
        
        supplierCount[msg.sender] = safeAdd(supplierCount[msg.sender],1);
        lockSupplier[msg.sender] = safeAdd(lockSupplier[msg.sender],_count);
        return true;
    }
    
    // update Contract state
    function updateContractState(uint _code,uint8 _state) public is_not_locked(msg.sender) returns (bool success) {
        require(supplierContractInfo[_code]._code != 0);
        require(supplierContractInfo[_code]._state != 1 && supplierContractInfo[_code]._state != 5);
        require(_state == 1 || _state == 5);
        require(balances[supplierContractInfo[_code]._from] >= lockSupplier[supplierContractInfo[_code]._from]);
        
        //error
        if(now >= supplierContractInfo[_code]._end_time){
            supplierContractInfo[_code]._state = 5;
            balances[supplierContractInfo[_code]._from] = safeSub(balances[supplierContractInfo[_code]._from],supplierContractInfo[_code]._count);
            balances[supplierContractInfo[_code]._to0] = safeAdd(balances[supplierContractInfo[_code]._to0],supplierContractInfo[_code]._count);
            lockSupplier[supplierContractInfo[_code]._from] = safeSub(lockSupplier[supplierContractInfo[_code]._from],supplierContractInfo[_code]._count);
            return true;
        }
        //the one
        if(supplierContractInfo[_code]._typ == 1){
            require(msg.sender == supplierContractInfo[_code]._to1);
            if(_state == 1){
                stateSuccess(_code);
                return true;
            }else if(_state == 5){
                stateFail(_code);
                return true;
            }
        }
        
        //the two
        if(supplierContractInfo[_code]._typ == 2){
            if(msg.sender == supplierContractInfo[_code]._to1 && _state == 1){
                supplierContractInfo[_code]._state = 2;
                return true;
            }else if(msg.sender == supplierContractInfo[_code]._to2 && _state == 1 && supplierContractInfo[_code]._state == 2){
                stateSuccess(_code);
                return true;
            }else if((msg.sender == supplierContractInfo[_code]._to1 || msg.sender == supplierContractInfo[_code]._to2) && _state == 5){
                stateFail(_code);
                return true;
            }
            require(1!=1);
        }
        
        //the three
        if(supplierContractInfo[_code]._typ == 3){
            if(msg.sender == supplierContractInfo[_code]._to1 && _state == 1){
                supplierContractInfo[_code]._state = 2;
                return true;
            }else if(msg.sender == supplierContractInfo[_code]._to2 && _state == 1 && supplierContractInfo[_code]._state == 2){
                supplierContractInfo[_code]._state = 3;
                return true;
            }else if(msg.sender == supplierContractInfo[_code]._to3 && _state == 1 && supplierContractInfo[_code]._state == 3){
                stateSuccess(_code);
                return true;
            }else if((msg.sender == supplierContractInfo[_code]._to1 || msg.sender == supplierContractInfo[_code]._to2 || msg.sender == supplierContractInfo[_code]._to3) && _state == 5){
                stateFail(_code);
                return true;
            }
            require(1!=1);
        }
        
        return false;
    }
    
    function stateFail(uint _code) private {
        supplierContractInfo[_code]._state = 5;
        lockSupplier[supplierContractInfo[_code]._from] = safeSub(lockSupplier[supplierContractInfo[_code]._from],supplierContractInfo[_code]._count);
    }
    
    function stateSuccess(uint _code) private {
        supplierContractInfo[_code]._state = 1;
        balances[supplierContractInfo[_code]._from] = safeSub(balances[supplierContractInfo[_code]._from],supplierContractInfo[_code]._count);
        balances[supplierContractInfo[_code]._sup] = safeAdd(balances[supplierContractInfo[_code]._sup],supplierContractInfo[_code]._count);
        lockSupplier[supplierContractInfo[_code]._from] = safeSub(lockSupplier[supplierContractInfo[_code]._from],supplierContractInfo[_code]._count);
    }
}