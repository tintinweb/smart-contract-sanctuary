/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
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
}

interface LiquiVault {
    function usersCount () external view returns (uint count);
    function farmers(uint index) external view returns (address);
    function users(address) external view returns (uint shares, uint unlockTime);
}

interface LiquiFarm {
    function usersCount () external view returns (uint count);
    function farmers(uint index) external view returns (address);
    function users(address) external view returns (uint managed, uint joined, uint w, uint c, uint r, uint b);
}

interface Token {
    function mint(address to, uint amount) external;
}

contract LiquiFarmMinter {

    using SafeMath for uint;
    
    LiquiFarm farm;
    Token liquiToken;

    struct UserInfo {
        uint claimed;
        uint minted;
    }

    uint[][] ems = [
          [1628456400, 50] // Aug-09-2021+ EM50
        , [1636236000, 20] // Nov-07-2021+ EM20
        , [1644012000, 10] // Feb-05-2022+ EM10
        , [1651784400, 5]  // May-06-2022+ EM05
        , [1659560400, 2]  // Aug-04-2022+ EM02
        , [1667340000, 1]  // Nov-06-2022+ EM01
        , [1675116000, 0]  // Jan-01-2023+ EM00
    ];
    
    address owner;
    
    mapping(address => UserInfo) users;
    
    constructor() {
        owner = msg.sender;
    }

    function initialize(address liquiAddress, address liquiFarm ) public {
        require(
            msg.sender == owner 
            && address(farm) == address(0) 
            && address(liquiToken) == address(0), 'forbidden'
        );
        farm = LiquiFarm(liquiFarm);
        liquiToken = Token(liquiAddress);        
    }
    
    function em(uint input) public view returns (uint) {
        for(uint i = 0; i < ems.length - 1; i++) {
            if(ems[i][0] < block.timestamp && block.timestamp < ems[i+1][0]) {
                return input.mul(ems[i][1]);
            }
        }
        return input.mul(ems[ems.length - 1][1]);
    }
    
    function batchForward() public {
        uint count = farm.usersCount();
        for(uint i = 0; i < count; i++) {
            harvest(farm.farmers(i));
        }
    }
    
    function harvest(address farmer) private {
        UserInfo storage user = users[farmer];
        (, , , uint collected, , ) = farm.users(farmer);
        uint delta = collected.sub(user.claimed);
        if(delta > 0) {
            uint emission = em(delta);
            user.claimed = user.claimed.add(delta);
            user.minted = user.minted.add(emission);
            liquiToken.mint(farmer, emission);
        }        
    }
    
    function harvest() public {
        harvest(msg.sender);
    }
}

contract LiquiVaultMinter {

    using SafeMath for uint;
    
    LiquiVault vault;
    Token liquiToken;

    struct UserInfo {
        uint claimed;
        uint minted;
    }

    uint[][] ems = [
          [1628456400, 50] // Aug-09-2021+ EM50
        , [1636236000, 20] // Nov-07-2021+ EM20
        , [1644012000, 10] // Feb-05-2022+ EM10
        , [1651784400, 5]  // May-06-2022+ EM05
        , [1659560400, 2]  // Aug-04-2022+ EM02
        , [1667340000, 1]  // Nov-06-2022+ EM01
        , [1675116000, 0]  // Jan-01-2023+ EM00
    ];
    
    address owner;
    
    mapping(address => UserInfo) users;
    
    constructor() {
        owner = msg.sender;
    }

    function initialize(address liquiAddress, address liquiVault ) public {
        require(
            msg.sender == owner 
            && address(vault) == address(0) 
            && address(liquiToken) == address(0), 'forbidden'
        );
        vault = LiquiVault(liquiVault);
        liquiToken = Token(liquiAddress);        
    }
    
    function em(uint input) public view returns (uint) {
        for(uint i = 0; i < ems.length - 1; i++) {
            if(ems[i][0] < block.timestamp && block.timestamp < ems[i+1][0]) {
                return input.mul(ems[i][1]);
            }
        }
        return input.mul(ems[ems.length - 1][1]);
    }
    
    function harvest(address farmer) private {
        UserInfo storage user = users[farmer];
        (uint shares, uint unlockTime) = vault.users(farmer);
        if(user.claimed < unlockTime) {
            uint emission = em(shares);
            user.claimed = unlockTime;
            user.minted = user.minted.add(emission);
            liquiToken.mint(farmer, emission);
        }        
    }
    
    function harvest() public {
        harvest(msg.sender);
    }
}

contract LiquiToken {
    
    string public name = "LIQUI Token";       
    string public symbol = "LIQUI";           

    uint256 public decimals = 18;
    uint256 public totalSupply = 0;
    
    mapping(address => bool) isMinter;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    address owner;

    constructor () {
        owner = msg.sender;
    }
    
    function addMinter(address minter) public {
        require(msg.sender == owner, 'forbidden');
        isMinter[minter] = true;
    }
    
    function removeMinter(address minter) public {
        require(msg.sender == owner, 'forbidden');
        isMinter[minter] = false;
    }
    
    function mint(address to, uint amount) public {
        require(isMinter[msg.sender], 'only minter');
        totalSupply += amount;
        balanceOf[to] = amount;
        emit Transfer(address(0x0), to, amount);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, uint256 _value) public  returns (bool success) {
        return transferFrom(_from, msg.sender, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[address(0x0)] += _value;
        emit Transfer(msg.sender, address(0x0), _value);
    }
}