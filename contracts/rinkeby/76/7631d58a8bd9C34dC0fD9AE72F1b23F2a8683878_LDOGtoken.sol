/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;

contract LDOGtoken {
    
    string LDoggie = "LDoggie";
    string LDOG = "LDOG";
    uint totalsupNUM;
    uint decimalnum = 9;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) RewardsClaimed;
    uint256 total;
    bool Gone;
    uint LDOGrewards;
    
    ///////////////////////////////////////////////////
    address DevFund;
    address LiquidityFund;
    //////////////////////////////////////////////////
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event ThrewAwayTheKeys(bool Gone);
    
    ////////////////////////////////////////////////////////////////////////////////////
    
    function name() public view returns (string memory){
        
        return LDoggie;
    }
    
    function symbol() public view returns (string memory) {
        
        return LDOG;
    }
    
    function totalsupply() public view returns (uint) {
        
        return totalsupNUM;
    }
    
    function decimals() public view returns (uint) {
        
        return decimalnum;
    }

    //////////////////////////////////////////////////////////////////////////////////////

    function transfer(address _to, uint256 _value) public returns (bool success) {
        
        require(balances[msg.sender] >= _value && _value > 0);
       
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            
            RewardsClaimed[_to] += _value;
            RewardsClaimed[msg.sender] -= _value;
            ////////////////////////////////////////////
            balances[DevFund] += (_value/10)/3;
            balances[LiquidityFund] += (_value/10)/3;
            LDOGrewards += (_value/10)/3;
            ////////////////////////////////////////////
            balances[_to] += _value - _value/10;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
      
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value - _value/10;
            balances[_from] -= _value;
            
            RewardsClaimed[_to] += _value;
            RewardsClaimed[_from] -= _value;
            ////////////////////////////////////////////
            balances[DevFund] += (_value/10)/3;
            balances[LiquidityFund] += (_value/10)/3;
            LDOGrewards += (_value/10)/3;
            ////////////////////////////////////////////
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
    
    address MasterAddress = 0xC65423A320916d7DAF86341De6278d02c7E1D3B1;
    
    function MintLDOG(uint Amount) public {
        
        require(MasterAddress == msg.sender);
        
        totalsupNUM = totalsupNUM + Amount;
        balances[msg.sender] = balances[msg.sender] + Amount;
    }
    
    function BurnLDOG(uint Amount) public {
        
        require(balances[msg.sender] >= Amount && Amount > 0);
        
        totalsupNUM = totalsupNUM - Amount;
        balances[msg.sender] = balances[msg.sender] - Amount;
    }
    
    function ThrowAwayTheMintingKeys() public {
        
        require(MasterAddress == msg.sender);
        
        MasterAddress = 0x0000000000000000000000000000000000000000;
        Gone == true;
        emit ThrewAwayTheKeys(Gone);
    }
    
    ////////////////////////////////////////////////////////////////////////////////////
    
    function ClaimRewards() public {
        
        uint percentageofsupply;
        uint rewardamount;
        percentageofsupply = totalsupNUM/balances[msg.sender];
        
        rewardamount = (LDOGrewards*percentageofsupply) - RewardsClaimed[msg.sender];
        
        require(rewardamount > 0);
        
        RewardsClaimed[msg.sender] += rewardamount;
        balances[msg.sender] += rewardamount;
    }
}