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

interface IContractStakeToken {
    function depositToken(address _investor, uint8 _stakeType, uint256 _time, uint256 _value) external returns (bool);
    function validWithdrawToken(address _address, uint256 _now) public returns (uint256);
    function withdrawToken(address _address) public returns (uint256);
    function cancel(uint256 _index, address _address) public returns (bool _result);
    function changeRates(uint8 _numberRate, uint256 _percent) public returns (bool);


    function getBalanceTokenContract() public view returns (uint256);
    function balanceOfToken(address _owner) external view returns (uint256 balance);
    function getTokenStakeByIndex(uint256 _index) public view returns (
        address _owner,
        uint256 _amount,
        uint8 _stakeType,
        uint256 _time,
        uint8 _status
    );
    function getTokenTransferInsByAddress(address _address, uint256 _index) public view returns (
        uint256 _indexStake,
        bool _isRipe
    );
    function getCountTransferInsToken(address _address) public view returns (uint256 _count);
    function getCountStakesToken() public view returns (uint256 _count);
    function getTotalTokenDepositByAddress(address _owner) public view returns (uint256 _amountEth);
    function getTotalTokenWithdrawByAddress(address _owner) public view returns (uint256 _amountEth);
    function setContractAdmin(address _admin, bool _isAdmin) public;

    function setContractUser(address _user, bool _isUser) public;
    function calculator(uint8 _currentStake, uint256 _amount, uint256 _amountHours) public view returns (uint256 stakeAmount);
}

interface IContractErc20Token {
    function transfer(address _to, uint256 _value) returns (bool success);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool);
    function approve(address _spender, uint256 _value) returns (bool);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

contract RapidProfit is Ownable {
    using SafeMath for uint256;
    IContractStakeToken public contractStakeToken;
    IContractErc20Token public contractErc20Token;

    uint256 public balanceTokenContract;

    event WithdrawEther(address indexed receiver, uint256 amount);
    event WithdrawToken(address indexed receiver, uint256 amount);

    function RapidProfit(address _owner) public {
        require(_owner != address(0));
        owner = _owner;
        //owner = msg.sender; // for test&#39;s
    }

    // fallback function can be used to buy tokens
    function() payable public {
    }

    function setContractStakeToken (address _addressContract) public onlyOwner {
        require(_addressContract != address(0));
        contractStakeToken = IContractStakeToken(_addressContract);
    }

    function setContractErc20Token (address _addressContract) public onlyOwner {
        require(_addressContract != address(0));
        contractErc20Token = IContractErc20Token(_addressContract);
    }

    function depositToken(address _investor, uint8 _stakeType, uint256 _value) external payable returns (bool){
        require(_investor != address(0));
        require(_value > 0);
        require(contractErc20Token.allowance(_investor, this) >= _value);

        bool resultStake = contractStakeToken.depositToken(_investor, _stakeType, now, _value);
        balanceTokenContract = balanceTokenContract.add(_value);
        bool resultErc20 = contractErc20Token.transferFrom(_investor, this, _value);

        return (resultStake && resultErc20);
    }

    function validWithdrawToken(address _address, uint256 _now) public returns (uint256 result){
        require(_address != address(0));
        require(_now > 0);
        result = contractStakeToken.validWithdrawToken(_address, _now);
    }

    function balanceOfToken(address _owner) public view returns (uint256 balance) {
        return contractStakeToken.balanceOfToken(_owner);
    }

    function getCountStakesToken() public view returns (uint256 result) {
        result = contractStakeToken.getCountStakesToken();
    }

    function getCountTransferInsToken(address _address) public view returns (uint256 result) {
        result = contractStakeToken.getCountTransferInsToken(_address);
    }

    function getTokenStakeByIndex(uint256 _index) public view returns (
        address _owner,
        uint256 _amount,
        uint8 _stakeType,
        uint256 _time,
        uint8 _status
    ) {
        (_owner, _amount, _stakeType, _time, _status) = contractStakeToken.getTokenStakeByIndex(_index);
    }

    function getTokenTransferInsByAddress(address _address, uint256 _index) public view returns (
        uint256 _indexStake,
        bool _isRipe
    ) {
        (_indexStake, _isRipe) = contractStakeToken.getTokenTransferInsByAddress(_address, _index);
    }

    function removeContract() public onlyOwner {
        selfdestruct(owner);
    }

    function calculator(uint8 _currentStake, uint256 _amount, uint256 _amountHours) public view returns (uint256 result){
        result = contractStakeToken.calculator(_currentStake, _amount, _amountHours);
    }

    function getBalanceEthContract() public view returns (uint256){
        return this.balance;
    }

    function getBalanceTokenContract() public view returns (uint256 result){
        return contractErc20Token.balanceOf(this);
    }

    function withdrawToken(address _address) public returns (uint256 result){
        uint256 amount = contractStakeToken.withdrawToken(_address);
        require(getBalanceTokenContract() >= amount);
        bool success = contractErc20Token.transfer(_address, amount);
        //require(success);
        WithdrawToken(_address, amount);
        result = amount;
    }

    function cancelToken(uint256 _index) public returns (bool result) {
        require(_index >= 0);
        require(msg.sender != address(0));
        result = contractStakeToken.cancel(_index, msg.sender);
    }

    function changeRatesToken(uint8 _numberRate, uint256 _percent) public onlyOwner returns (bool result) {
        result = contractStakeToken.changeRates(_numberRate, _percent);
    }

    function getTotalTokenDepositByAddress(address _owner) public view returns (uint256 result) {
        result = contractStakeToken.getTotalTokenDepositByAddress(_owner);
    }

    function getTotalTokenWithdrawByAddress(address _owner) public view returns (uint256 result) {
        result = contractStakeToken.getTotalTokenWithdrawByAddress(_owner);
    }

    function withdrawOwnerEth(uint256 _amount) public onlyOwner returns (bool) {
        require(this.balance >= _amount);
        owner.transfer(_amount);
        WithdrawEther(owner, _amount);
    }

    function withdrawOwnerToken(uint256 _amount) public onlyOwner returns (bool) {
        require(getBalanceTokenContract() >= _amount);
        contractErc20Token.transfer(owner, _amount);
        WithdrawToken(owner, _amount);
    }

}