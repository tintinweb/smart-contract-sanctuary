/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

pragma solidity 0.8.7;

contract MyCoin{
    string COIN_NAME = "Abu Test Coin";
    string COIN_SYMBOL = "ATC";
    uint256 total_supply = 10000000 * 1e8;
    uint8 decimal = 8;

    address owner;        
    mapping (address => uint) balanceLedger;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(){
        owner = msg.sender;
        balanceLedger[owner] = 1000000 * 1e8;
    }

    function name() public view returns (string memory)
    {
        return COIN_NAME;
    }
    function symbol() public view returns (string memory)
    {
        return COIN_SYMBOL;
    }
    function decimals() public view returns (uint8) {
        return decimal;
    }
    function totalSupply() public view returns (uint256){
        return total_supply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balanceLedger[_owner];
    }
    function transfer(address _to, uint256 _value) public returns (bool success){
        assert (balanceLedger[msg.sender] >_value);
        balanceLedger[msg.sender] = balanceLedger[msg.sender] - _value;
        balanceLedger[_to] = balanceLedger[_to] + _value;

        emit Transfer(msg.sender,_to,_value);

        return true;
    }

    //mapping(uint => bool) rewardClaimedHistory;
    uint totalMinted = 1000000 *1e8;
    // function mine() external returns (bool success)
    // {
    //     if(!rewardClaimedHistory[block.number] && block.number % 10 == 0)
    //     {
    //         balanceLedger[msg.sender] += 10 *1e8;
    //         totalMinted += 10 *1e8;
    //         rewardClaimedHistory[block.number] = true;
    //         return true;
    //     }
    //     return false;

    // }
    
    function getBlockNumber() public view returns(uint)
    {
        return block.number;
    }
    // function isMined(uint blockNumber) public view returns(bool)
    // {
    //     return rewardClaimedHistory[blockNumber];
    // }

    mapping (address => mapping(address => uint)) allowances;
    function approve(address _spender, uint256 _value) public returns (bool success){
       allowances[msg.sender][_spender] = _value;

       emit Approval(msg.sender,_spender,_value);

       return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        if(allowances[_from][msg.sender] >= _value && balanceLedger[_from] >= _value)
        {
            balanceLedger[_to] += _value;
            balanceLedger[_from] -= _value;
            allowances[_from][msg.sender] -=_value;

            emit Transfer(_from,_to,_value);

            return true;
        }
        return false;
    }

    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowances[_owner][_spender];
    }
}