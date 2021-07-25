/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity 0.8.4;


contract FuelTokenContract {
    string public name = "Fuel Token";
    string public symbol = "FUEL";
    uint256 public totalSupply = 500000000000000000000000; // 0.5 million tokens
    mapping(uint => uint256) public icoSupplyMap;
    mapping(uint => uint) public rates;
    uint256 public icoSupply = 50000 ether;
    uint256 public idoSupply = 100000 ether;
    uint8 public decimals = 18;
    uint public idoUId = 0;
    uint public idoValue = 1000 ether;
    uint public icoPhase = 1;
    bool public icoCompleted = false;
    address public owner;
    uint public transFees = 5;
    
    struct User {
        bool exist;
        uint id;
        uint cTime;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);
    event IDOBuy(address indexed _user,uint256 _value,uint time);
    event ICOBuy(address indexed _user,uint256 _value,uint time,uint rate);
    event IDOBonusTransfer(address indexed _from, address indexed _to, uint256 _value,uint time);

    mapping(address => uint256) public balanceOf;
    mapping(address => User) public idoUsers;
    mapping(uint => address) public idToAddress;
    mapping(address => mapping(address => uint256)) public allowed;

    modifier onlyOwner(){
        require(msg.sender==owner,"only owner allowed");
        _;
    }

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply - icoSupply - idoSupply;
        for(uint i=1;i<=5;i++){
            icoSupplyMap[i] = 10000 ether;
        }
        rates[1] = 50000;
        rates[2] = 40000;
        rates[3] = 30000;
        rates[4] = 20000;
        rates[5] = 10000;
    }
    
    function buyIDO() public payable returns (bool) {
        require(idoSupply >= idoValue,"IDO not available");
        require(!idoUsers[msg.sender].exist,"you can buy IDO only one time");
        require(msg.value == 0.1 ether,"sent value is not correct");
        
        idoUId++;
        User memory uObj = User(true,idoUId,block.timestamp);
        idoUsers[msg.sender] = uObj;
        idToAddress[idoUId] = msg.sender;
        balanceOf[msg.sender] += idoValue;
        idoSupply -= idoValue;
        emit IDOBuy(msg.sender,msg.value,block.timestamp);
        return true;
    }
    
    function buyICO() public payable returns (bool) {
        require(!icoCompleted,"ICO completed");
        uint256 _value = 0;
        uint256 rate = rates[icoPhase];
        if(icoSupplyMap[icoPhase] > 0){
            _value = msg.value * rate;
            if(_value > icoSupplyMap[icoPhase]){
                revert("bnb sent not correct");
            }else{
                icoSupply -= _value;
                icoSupplyMap[icoPhase] -= _value;
            }
        }
        if(icoSupplyMap[icoPhase] == 0){
            icoPhase++;
            if(icoPhase==6){
                icoCompleted = true;
            }
        }
        
        balanceOf[msg.sender] += _value;
        emit ICOBuy(msg.sender,msg.value,block.timestamp,rate);
        return true;
    }
    
    function allowance(address allow_owner, address delegate) public view returns (uint) {
        return allowed[allow_owner][delegate];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        if(idoUsers[msg.sender].exist){
            if((balanceOf[msg.sender] - _value) < (1000 ether) && block.timestamp < (idoUsers[msg.sender].cTime + 15778458)){
                revert("your funds are locked for while");
            }
        }
        
        balanceOf[msg.sender] -= _value;
        if(idoUId>0){
            uint256 fees = (_value * transFees)/100;
            uint256 eachAmt = fees/idoUId;
            for(uint i=1;i<=idoUId;i++){
                balanceOf[idToAddress[i]] += eachAmt;
                emit IDOBonusTransfer(msg.sender,idToAddress[i],eachAmt,block.timestamp);
            }
            balanceOf[_to] += (_value - fees);
            emit Transfer(msg.sender, _to, (_value - fees));
        }else{
            balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
        }
        
        return true;
    }
    
     function transferBNB(address _to, uint256 _value) public onlyOwner returns (bool success) {
        require(_value<=address(this).balance,"balance is not sufficient");
        payable(_to).transfer(_value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from,address _to,uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}