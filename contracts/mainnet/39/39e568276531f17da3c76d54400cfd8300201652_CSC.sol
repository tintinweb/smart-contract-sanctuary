pragma solidity ^0.4.23;

contract CSC {
    mapping (address => uint256) private balances;
    mapping (address => uint256[2]) private lockedBalances;
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX
    uint256 public totalSupply;
    address public owner;
        uint256 private icoLockUntil = 1543593540;
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    constructor(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        address _owner,
        address[] _lockedAddress,
        uint256[] _lockedBalances,
        uint256[] _lockedTimes
    ) public {
        balances[_owner] = _initialAmount;                   // Give the owner all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        owner = _owner;                                      // set owner
        for(uint i = 0;i < _lockedAddress.length;i++){
            lockedBalances[_lockedAddress[i]][0] = _lockedBalances[i];
            lockedBalances[_lockedAddress[i]][1] = _lockedTimes[i];
        }
    }
    /*外部直投和空投
     */
    /*转账 会检测是否有锁仓限额和期限
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //当ICO未完成时，除owner外禁止转账
        require(msg.sender == owner || icoLockUntil < now);
        if(_to != address(0)){
            if(lockedBalances[msg.sender][1] >= now) {
                require((balances[msg.sender] > lockedBalances[msg.sender][0]) &&
                 (balances[msg.sender] - lockedBalances[msg.sender][0] >= _value));
            } else {
                require(balances[msg.sender] >= _value);
            }
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
    }
    /*从某地址摧毁某数量的代币并减少总供应量 需要拥有者权限
     */
    function burnFrom(address _who,uint256 _value)public returns (bool){
        require(msg.sender == owner);
        assert(balances[_who] >= _value);
        totalSupply -= _value;
        balances[_who] -= _value;
        lockedBalances[_who][0] = 0;
        lockedBalances[_who][1] = 0;
        return true;
    }
    /*铸币到创始者账户并增加总供应量 需要拥有者权限
     */
    function makeCoin(uint256 _value)public returns (bool){
        require(msg.sender == owner);
        totalSupply += _value;
        balances[owner] += _value;
        return true;
    }
    /*设置ICO锁仓到期时间，需要拥有管理者权限
     */
    function setIcoLockUntil(uint256 _until) public{
        require(msg.sender == owner);
        icoLockUntil = _until;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    /*将合约中的ETH提取到创始者地址中 需求拥有者权限
     */
    function withdraw() public{
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
    /*将合约中的ETH提取到某个地址中 需求拥有者权限
     */
    function withdrawTo(address _to) public{
        require(msg.sender == owner);
        address(_to).transfer(address(this).balance);
    }
}