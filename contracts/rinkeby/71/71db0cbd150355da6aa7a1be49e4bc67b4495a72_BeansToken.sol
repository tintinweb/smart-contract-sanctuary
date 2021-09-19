/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;

contract BeansToken {
    
    string beans = "Beans";
    string BEAN = "BEAN";
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 total;
    
    function name() public view returns (string memory){
        
        return beans;
    }
    
    function symbol() public view returns (string memory) {
        
        return BEAN;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    //////////////////////////////////////////////////////////////////////////////////////
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
    
    require(_value >= 0 && balances[msg.sender] >= _value);
        
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    //////////////////////////////////////////////////////////////////////////////////////
    
    function GetBean() public payable{
        
        require(balances[msg.sender] == 0, "You can only get beans if you don't have any!");
        balances[msg.sender] = balances[msg.sender] + 1;
    }
    
    mapping (address => uint256) timer;
    mapping (address => uint256) BeansPlanted;

    function PlantBeans(uint256 NumberofBeansYouWannaPlant) public {
        
        require(BeansPlanted[msg.sender] == 0, "Your pot is already full of bean plants, harvest your beans to plant another one!");
        require(NumberofBeansYouWannaPlant >= 0 && balances[msg.sender] >= NumberofBeansYouWannaPlant);
        
        timer[msg.sender] = block.timestamp;
        balances[msg.sender] = balances[msg.sender] - NumberofBeansYouWannaPlant;
        BeansPlanted[msg.sender] = NumberofBeansYouWannaPlant;
    } 
    
    function HarvestBeans() public {
        
        uint256 timepassed;
        uint256 rewards;
        block.timestamp - timer[msg.sender] == timepassed;
        
        BeansPlanted[msg.sender] * timepassed == rewards;
        
        balances[msg.sender] = balances[msg.sender] + rewards + BeansPlanted[msg.sender];
        BeansPlanted[msg.sender] = 0;
    }
    
    string checkrewardstext = "Beans waiting to be harvested: ";
    
    function CheckRewards(address PutYourAddressHere) public view returns(string memory, uint256){
        
        uint256 timepassed;
        uint256 rewards;
        block.timestamp - timer[PutYourAddressHere] == timepassed;
        
        BeansPlanted[msg.sender] * timepassed == rewards;
        
        return (checkrewardstext, rewards);
    }
}