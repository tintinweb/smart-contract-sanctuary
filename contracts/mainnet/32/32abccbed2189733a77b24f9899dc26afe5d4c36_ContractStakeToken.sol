pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function changeOwner(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }
}


contract ContractStakeToken is Ownable {
    using SafeMath for uint256;

    enum TypeStake {DAY, WEEK, MONTH}
    TypeStake typeStake;
    enum StatusStake {ACTIVE, COMPLETED, CANCEL}

    struct TransferInStructToken {
        uint256 indexStake;
        bool isRipe;
    }

    struct StakeStruct {
        address owner;
        uint256 amount;
        TypeStake stakeType;
        uint256 time;
        StatusStake status;
    }

    StakeStruct[] arrayStakesToken;

    uint256[] public rates = [101, 109, 136];

    uint256 public totalDepositTokenAll;

    uint256 public totalWithdrawTokenAll;

    mapping (address => uint256) balancesToken;
    mapping (address => uint256) totalDepositToken;
    mapping (address => uint256) totalWithdrawToken;
    mapping (address => TransferInStructToken[]) transferInsToken;
    mapping (address => bool) public contractUsers;

    event Withdraw(address indexed receiver, uint256 amount);

    function ContractStakeToken(address _owner) public {
        require(_owner != address(0));
        owner = _owner;
        //owner = msg.sender; // for test&#39;s
    }

    modifier onlyOwnerOrUser() {
        require(msg.sender == owner || contractUsers[msg.sender]);
        _;
    }

    /**
    * @dev Add an contract admin
    */
    function setContractUser(address _user, bool _isUser) public onlyOwner {
        contractUsers[_user] = _isUser;
    }

    // fallback function can be used to buy tokens
    function() payable public {
        //deposit(msg.sender, msg.value, TypeStake.DAY, now);
    }

    function depositToken(address _investor, TypeStake _stakeType, uint256 _time, uint256 _value) onlyOwnerOrUser external returns (bool){
        require(_investor != address(0));
        require(_value > 0);
        require(transferInsToken[_investor].length < 31);

        balancesToken[_investor] = balancesToken[_investor].add(_value);
        totalDepositToken[_investor] = totalDepositToken[_investor].add(_value);
        totalDepositTokenAll = totalDepositTokenAll.add(_value);
        uint256 indexStake = arrayStakesToken.length;

        arrayStakesToken.push(StakeStruct({
            owner : _investor,
            amount : _value,
            stakeType : _stakeType,
            time : _time,
            status : StatusStake.ACTIVE
            }));
        transferInsToken[_investor].push(TransferInStructToken(indexStake, false));

        return true;
    }

    /**
     * @dev Function checks how much you can remove the Token
     * @param _address The address of depositor.
     * @param _now The current time.
     * @return the amount of Token that can be withdrawn from contract
     */
    function validWithdrawToken(address _address, uint256 _now) public returns (uint256){
        require(_address != address(0));
        uint256 amount = 0;

        if (balancesToken[_address] <= 0 || transferInsToken[_address].length <= 0) {
            return amount;
        }

        for (uint i = 0; i < transferInsToken[_address].length; i++) {
            uint256 indexCurStake = transferInsToken[_address][i].indexStake;
            TypeStake stake = arrayStakesToken[indexCurStake].stakeType;
            uint256 stakeTime = arrayStakesToken[indexCurStake].time;
            uint256 stakeAmount = arrayStakesToken[indexCurStake].amount;
            uint8 currentStake = 0;
            if (arrayStakesToken[transferInsToken[_address][i].indexStake].status == StatusStake.CANCEL) {
                amount = amount.add(stakeAmount);
                transferInsToken[_address][i].isRipe = true;
                continue;
            }
            if (stake == TypeStake.DAY) {
                currentStake = 0;
                if (_now < stakeTime.add(1 days)) continue;
            }
            if (stake == TypeStake.WEEK) {
                currentStake = 1;
                if (_now < stakeTime.add(7 days)) continue;
            }
            if (stake == TypeStake.MONTH) {
                currentStake = 2;
                if (_now < stakeTime.add(730 hours)) continue;
            }
            uint256 amountHours = _now.sub(stakeTime).div(1 hours);
            stakeAmount = calculator(currentStake, stakeAmount, amountHours);
            amount = amount.add(stakeAmount);
            transferInsToken[_address][i].isRipe = true;
            arrayStakesToken[transferInsToken[_address][i].indexStake].status = StatusStake.COMPLETED;
        }
        return amount;
    }

    function withdrawToken(address _address) onlyOwnerOrUser public returns (uint256){
        require(_address != address(0));
        uint256 _currentTime = now;
        _currentTime = 1525651200; // for test
        uint256 _amount = validWithdrawToken(_address, _currentTime);
        require(_amount > 0);
        totalWithdrawToken[_address] = totalWithdrawToken[_address].add(_amount);
        totalWithdrawTokenAll = totalWithdrawTokenAll.add(_amount);
        while (clearTransferInsToken(_address) == false) {
            clearTransferInsToken(_address);
        }
        Withdraw(_address, _amount);
        return _amount;
    }

    function clearTransferInsToken(address _owner) private returns (bool) {
        for (uint i = 0; i < transferInsToken[_owner].length; i++) {
            if (transferInsToken[_owner][i].isRipe == true) {
                balancesToken[_owner] = balancesToken[_owner].sub(arrayStakesToken[transferInsToken[_owner][i].indexStake].amount);
                removeMemberArrayToken(_owner, i);
                return false;
            }
        }
        return true;
    }

    function removeMemberArrayToken(address _address, uint index) private {
        if (index >= transferInsToken[_address].length) return;
        for (uint i = index; i < transferInsToken[_address].length - 1; i++) {
            transferInsToken[_address][i] = transferInsToken[_address][i + 1];
        }
        delete transferInsToken[_address][transferInsToken[_address].length - 1];
        transferInsToken[_address].length--;
    }

    function balanceOfToken(address _owner) public view returns (uint256 balance) {
        return balancesToken[_owner];
    }

    function cancel(uint256 _index, address _address) onlyOwnerOrUser public returns (bool _result) {
        require(_index >= 0);
        require(_address != address(0));
        if(_address != arrayStakesToken[_index].owner){
            return false;
        }
        arrayStakesToken[_index].status = StatusStake.CANCEL;
        return true;
    }

    function withdrawOwner(uint256 _amount) public onlyOwner returns (bool) {
        require(this.balance >= _amount);
        owner.transfer(_amount);
        Withdraw(owner, _amount);
    }

    function changeRates(uint8 _numberRate, uint256 _percent) onlyOwnerOrUser public returns (bool) {
        require(_percent >= 0);
        require(0 <= _numberRate && _numberRate < 3);
        rates[_numberRate] = _percent.add(100);
        return true;

    }

    function getTokenStakeByIndex(uint256 _index) onlyOwnerOrUser public view returns (
        address _owner,
        uint256 _amount,
        TypeStake _stakeType,
        uint256 _time,
        StatusStake _status
    ) {
        require(_index < arrayStakesToken.length);
        _owner = arrayStakesToken[_index].owner;
        _amount = arrayStakesToken[_index].amount;
        _stakeType = arrayStakesToken[_index].stakeType;
        _time = arrayStakesToken[_index].time;
        _status = arrayStakesToken[_index].status;
    }

    function getTokenTransferInsByAddress(address _address, uint256 _index) onlyOwnerOrUser public view returns (
        uint256 _indexStake,
        bool _isRipe
    ) {
        require(_index < transferInsToken[_address].length);
        _indexStake = transferInsToken[_address][_index].indexStake;
        _isRipe = transferInsToken[_address][_index].isRipe;
    }

    function getCountTransferInsToken(address _address) public view returns (uint256 _count) {
        _count = transferInsToken[_address].length;
    }

    function getCountStakesToken() public view returns (uint256 _count) {
        _count = arrayStakesToken.length;
    }

    function getTotalTokenDepositByAddress(address _owner) public view returns (uint256 _amountToken) {
        return totalDepositToken[_owner];
    }

    function getTotalTokenWithdrawByAddress(address _owner) public view returns (uint256 _amountToken) {
        return totalWithdrawToken[_owner];
    }

    function removeContract() public onlyOwner {
        selfdestruct(owner);
    }

    function calculator(uint8 _currentStake, uint256 _amount, uint256 _amountHours) public view returns (uint256 stakeAmount){
        uint32 i = 0;
        uint256 number = 0;
        stakeAmount = _amount;
        if (_currentStake == 0) {
            number = _amountHours.div(24);
        }
        if (_currentStake == 1) {
            number = _amountHours.div(168);
        }
        if (_currentStake == 2) {
            number = _amountHours.div(730);
        }
        while(i < number){
            stakeAmount= stakeAmount.mul(rates[_currentStake]).div(100);
            i++;
        }
    }

}