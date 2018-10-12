pragma solidity ^0.4.18;




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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





/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}








/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}









/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}









/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}




/**
 * @title Math
 * @dev Assorted math operations
 */

library Math {
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
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        
        

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}





/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
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
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}









contract Jewel {
    function incise(address owner, uint256 value) external returns (uint);
}

contract DayQualitys {
    function getAreaQualityByDay(uint32 time, uint32 area) external returns (uint32);
}

contract Mineral is BurnableToken, Ownable {

    string public name = "Mineral";
    string public symbol = "ORE";
    uint8 public decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 800 * 1000 * 1000 * (10 ** uint256(decimals));

    uint public constant MINER_4_HOURS = 0.0005 ether;
    uint public constant MINER_8_HOURS = 0.001 ether;
    uint public constant MINER_24_HOURS = 0.003 ether;

    mapping(address => uint[][72]) public deployRange;

    
    
    uint public timeScale = 1; 

    
    
    mapping(uint32 => uint32[3][72]) private areaHourDeployed;

    
    struct AreaHourDeployed {
        uint32[72] lastCollectHour;
        
        mapping(uint32 => uint32[3][72]) hour; 
    }
    
    
    mapping(address => AreaHourDeployed) private userAreaHourDeployed;

    
    uint8 public constant CHECK_POINT_HOUR = 4;

    
    
    mapping(uint32 => uint32[72]) private areaCheckPoints;

    
    mapping(uint32 => uint) private dayAverageOutput;

    
    struct AreaCheckPoint {
        
        mapping(uint32 => uint32[72]) hour;
    }

    
    
    mapping(address => AreaCheckPoint) private userAreaCheckPoints;

    uint256 amountEther;

    
    mapping (address => uint) public remainEther;

    uint32 public constractDeployTime = uint32(now) / 1 hours * 1 hours;

    mapping(address => uint) activeArea; 
    
    bool enableWhiteList = true;
    mapping(address => bool) whiteUserList;    
    address serverAddress;

    address coldWallet;

    bool enableCheckArea = true;

    Jewel public jewelContract;
    DayQualitys public dayQualitysContract;

    event Pause();
    event Unpause();

    bool public paused = false;

    function Mineral() public {
        totalSupply = INITIAL_SUPPLY;
        balances[this] = 300 * 1000 * 1000 * (10 ** uint256(decimals));
        balances[msg.sender] = INITIAL_SUPPLY - balances[this];
        dayAverageOutput[0] = 241920 * 10 ** uint256(decimals);
    }

    /*
    function setTimeScale(uint scale) public onlyOwner {
        timeScale = scale;
    }

    
    function setConstractDeployTime(uint32 time) public onlyOwner {
        constractDeployTime = time;
    }*/

    function setColdWallet(address _coldWallet) public onlyOwner {
        coldWallet = _coldWallet;
    }

    function disableWhiteUserList() public onlyOwner {
        enableWhiteList = false;
    }

    function disableCheckArea() public onlyOwner {
        enableCheckArea = false;
    }

    modifier checkWhiteList() {
        if (enableWhiteList) {
            require(whiteUserList[msg.sender]);
        }
        _;
    }

    function setServerAddress(address addr) public onlyOwner {
        serverAddress = addr;
    }

    function authUser(string addr) public {
        require(msg.sender == serverAddress || msg.sender == owner);
        address s = bytesToAddress(bytes(addr));
        whiteUserList[s] = true;
    }

    function bytesToAddress (bytes b) internal view returns (address) {
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 16 + (c - 48);
            }
            if(c >= 65 && c <= 90) {
                result = result * 16 + (c - 55);
            }
            if(c >= 97 && c <= 122) {
                result = result * 16 + (c - 87);
            }
        }
        return address(result);
    }

    function setDayQualitys(address dayQualitys) public onlyOwner {
        dayQualitysContract = DayQualitys(dayQualitys);
    }

    function getMyDeployAt(uint32 area, uint32 hour) public view returns (uint32[3]) {
        return userAreaHourDeployed[msg.sender].hour[hour][area];
    }

    function getMyMinersAt(uint32 area, uint32 hour) public view returns (uint32) {
        return _getUserMinersAt(msg.sender, area, hour);
    }

    function _getUserMinersAt(address user, uint32 area, uint32 hour) internal view returns(uint32) {
        //now start from start&#39;s nearest check point
        uint32 nc = hour/CHECK_POINT_HOUR*CHECK_POINT_HOUR;
        if (userAreaCheckPoints[user].hour[nc][area] == 0 && userAreaCheckPoints[user].hour[nc + CHECK_POINT_HOUR][area] == 0) {
            return 0;
        }
        uint32 h = 0;
        int64 userInc = 0;
        uint32[3] storage ptUser;
        AreaHourDeployed storage _userAreaHourDeployed = userAreaHourDeployed[user];
        
        for (h = nc; h <= hour; ++h) {
            
            
            
            ptUser = _userAreaHourDeployed.hour[h][area];
            userInc += ptUser[0] + ptUser[1] + ptUser[2] - _userAreaHourDeployed.hour[h - 4][area][0] - 
                _userAreaHourDeployed.hour[h - 8][area][1] - _userAreaHourDeployed.hour[h - 24][area][2];
        }
        return userAreaCheckPoints[user].hour[nc][area] + uint32(userInc);
    }

    function getDeployAt(uint32 area, uint32 hour) public view returns (uint32[3]) {
        return areaHourDeployed[hour][area];
    }


    function getMinersAt(uint32 area, uint32 hour) public view returns (uint32) {
        return _getMinersAt(area, hour);
    }

    function _getMinersAt(uint32 area, uint32 hour) internal view returns (uint32) {
        //now start from start&#39;s nearest check point
        uint32 nc = hour/CHECK_POINT_HOUR*CHECK_POINT_HOUR;
        uint32 h = 0;
        int64 userInc = 0;
        int64 totalInc = 0;
        uint32[3] storage ptArea;
        
        for (h = nc; h <= hour; ++h) {
            
            
            
            ptArea = areaHourDeployed[h][area];
            totalInc += ptArea[0] + ptArea[1] + ptArea[2] - areaHourDeployed[h - 4][area][0] - areaHourDeployed[h - 8][area][1] - areaHourDeployed[h - 24][area][2];
        }

        return areaCheckPoints[nc][area] + uint32(totalInc);
    }

    function updateArea(uint areaId) internal pure returns (uint) {
        
        uint row = areaId / 8;
        uint colum = areaId % 8;

        uint result = uint(1) << areaId;
        if (row-1 >= 0) {
            result |= uint(1) << ((row-1)*8+colum);
        }
        if (row+1 < 9) {
            result |= uint(1) << ((row+1)*8+colum);
        }
        if (colum-1 >= 0) {
            result |= uint(1) << (row*8+colum-1);
        }
        if (colum+1 < 8) {
            result |= uint(1) << (row*8+colum+1);
        }
        
        return result;
    }

    function checkArea(uint32[] area, address user) internal {
        if (enableCheckArea) {
            uint[] memory distinctArea = new uint[](area.length);
            uint distinctAreaLength = 0;
        
            for (uint i = 0; i < area.length; i++) {
                bool find = false;
                for (uint j = 0; j < distinctAreaLength; j++) {
                    if (distinctArea[j] == area[i]) {
                        find = true;
                        break;
                    }
                }     
                if (!find) {
                    distinctArea[distinctAreaLength] = area[i];
                    distinctAreaLength += 1;
                }
            }

            if (activeArea[user] == 0) {
                require(distinctAreaLength == 1);
                activeArea[user] = updateArea(distinctArea[0]);
            } else {
                uint userActiveArea = activeArea[user];
                uint updateActiveArea = userActiveArea;
                for (i = 0; i < distinctAreaLength; i++) {
                    require(userActiveArea & uint(1) << distinctArea[i] > 0);
                    updateActiveArea = updateActiveArea | updateArea(distinctArea[i]);
                }

                activeArea[user] = updateActiveArea;
            }
        }
    }

    function deployMiners(address user, uint32[] area, uint32[] period, uint32[] count) public checkWhiteList whenNotPaused payable {
        require(area.length > 0);
        require(area.length == period.length);
        require(area.length == count.length);
        address _user = user;
        if (_user == address(0)) {
            _user = msg.sender;
        }
        
        uint32 _hour = uint32((now - constractDeployTime) * timeScale / 1 hours);

        checkArea(area, user);
        
        uint payment = _deployMiners(_user, _hour, area, period, count);
        _updateCheckPoints(_user, _hour, area, period, count);

        require(payment <= msg.value);
        remainEther[msg.sender] += (msg.value - payment);
        if (coldWallet != address(0)) {
            coldWallet.transfer(payment);
        } else {
            amountEther += payment;
        }
        
    }

    /*function deployMinersTest(uint32 _hour, address user, uint32[] area, uint32[] period, uint32[] count) public checkWhiteList payable {
        require(area.length > 0);
        require(area.length == period.length);
        require(area.length == count.length);
        address _user = user;
        if (_user == address(0)) {
            _user = msg.sender;
        }
        

        checkArea(area, user);
        
        uint payment = _deployMiners(_user, _hour, area, period, count);
        _updateCheckPoints(_user, _hour, area, period, count);

        require(payment <= msg.value);
        remainEther[msg.sender] += (msg.value - payment);
        amountEther += payment;
    }*/

    function _deployMiners(address _user, uint32 _hour, uint32[] memory area, uint32[] memory period, uint32[] memory count) internal returns(uint){
        uint payment = 0;
        uint32 minerCount = 0;
        uint32[3][72] storage _areaDeployed = areaHourDeployed[_hour];
        uint32[3][72] storage _userAreaDeployed = userAreaHourDeployed[_user].hour[_hour];
        
        
        for (uint index = 0; index < area.length; ++index) {
            require (period[index] == 4 || period[index] == 8 || period[index] == 24);
            if (period[index] == 4) {
                _areaDeployed[area[index]][0] += count[index];
                _userAreaDeployed[area[index]][0] += count[index];
                payment += count[index] * MINER_4_HOURS;
            } else if (period[index] == 8) {
                _areaDeployed[area[index]][1] += count[index];
                _userAreaDeployed[area[index]][1] += count[index];
                payment += count[index] * MINER_8_HOURS;
            } else if (period[index] == 24) {
                _areaDeployed[area[index]][2] += count[index];
                _userAreaDeployed[area[index]][2] += count[index];
                payment += count[index] * MINER_24_HOURS;
            }
            minerCount += count[index];
            DeployMiner(_user, area[index], _hour, _hour + period[index], count[index]);

            adjustDeployRange(area[index], _hour, _hour + period[index]);
        }
        return payment;
    }   

    function adjustDeployRange(uint area, uint start, uint end) internal {
        uint len = deployRange[msg.sender][area].length;
        if (len == 0) {
            deployRange[msg.sender][area].push(start | (end << 128));
        } else {
            uint s = uint128(deployRange[msg.sender][area][len - 1]);
            uint e = uint128(deployRange[msg.sender][area][len - 1] >> 128);
            
            if (start >= s && start < e) {
                end = e > end ? e : end;
                deployRange[msg.sender][area][len - 1] = s | (end << 128);
            } else {
                deployRange[msg.sender][area].push(start | (end << 128));
            }
        }
    }

    function getDeployArrayLength(uint area) public view returns (uint) {
        return deployRange[msg.sender][area].length;
    }
    
    function getDeploy(uint area, uint index) public view returns (uint,uint) {
        uint s = uint128(deployRange[msg.sender][area][index]);
        uint e = uint128(deployRange[msg.sender][area][index] >> 128);
        return (s, e);
    }

    function _updateCheckPoints(address _user, uint32 _hour, uint32[] memory area, uint32[] memory period, uint32[] memory count) internal {
        uint32 _area = 0;
        uint32 _count = 0;
        uint32 ce4 = _hour + 4;
        uint32 ce8 = _hour + 8;
        uint32 ce24 = _hour + 24;
        uint32 cs = (_hour/CHECK_POINT_HOUR+1)*CHECK_POINT_HOUR;
        AreaCheckPoint storage _userAreaCheckPoints = userAreaCheckPoints[_user];
        uint32 cp = 0;
        for (uint index = 0; index < area.length; ++index) {
            _area = area[index];
            _count = count[index];
            if (period[index] == 4) {
                for (cp = cs; cp <= ce4; cp += CHECK_POINT_HOUR) {
                    areaCheckPoints[cp][_area] += _count;
                    _userAreaCheckPoints.hour[cp][_area] += _count;
                }
            } else if (period[index] == 8) {
                for (cp = cs; cp <= ce8; cp += CHECK_POINT_HOUR) {
                    areaCheckPoints[cp][_area] += _count;
                    _userAreaCheckPoints.hour[cp][_area] += _count;
                }
            } else if (period[index] == 24) {
                for (cp = cs; cp <= ce24; cp += CHECK_POINT_HOUR) {
                    areaCheckPoints[cp][_area] += _count;
                    _userAreaCheckPoints.hour[cp][_area] += _count;
                }
            }
        }
    }

    

    event DeployMiner(address addr, uint32 area, uint32 start, uint32 end, uint32 count);

    event Collect(address addr, uint32 area, uint32 start, uint32 end, uint areaCount);

    function getMyLastCollectHour(uint32 area) public view returns (uint32){
        return userAreaHourDeployed[msg.sender].lastCollectHour[area];
    }

    
    
    function collect(address user, uint32[] area) public  checkWhiteList whenNotPaused {
        require(address(dayQualitysContract) != address(0));
        uint32 current = uint32((now - constractDeployTime) * timeScale / 1 hours);
        require(area.length > 0);
        address _user = user;
        if (_user == address(0)) {
            _user = msg.sender;
        }
        uint total = 0;
        
        for (uint a = 0; a < area.length; ++a) {
            uint len = deployRange[msg.sender][area[a]].length;
            bool finish = true;
            for (uint i = 0; i < len; i += 1) {
                uint s = uint128(deployRange[msg.sender][area[a]][i]);
                uint e = uint128(deployRange[msg.sender][area[a]][i] >> 128);
                if (current < e && current >= s ) {
                    total += _collect(_user, uint32(s), current, area[a]);
                    
                    deployRange[msg.sender][area[a]][i] = current | (e << 128);
                    finish = false;
                } else if (current >= e) {
                    total += _collect(_user, uint32(s), uint32(e), area[a]);
                }
            }
            
            if (finish) {
                deployRange[msg.sender][area[a]].length = 0;
            } else {
                deployRange[msg.sender][area[a]][0] = deployRange[msg.sender][area[a]][len - 1];
                deployRange[msg.sender][area[a]].length = 1;
            }
        }    

        ERC20(this).transfer(_user, total);
    }

    function _collect(address _user, uint32 start, uint32 end, uint32 area) internal returns (uint) {
        uint result = 0;
        uint32 writeCount = 1;
        uint income = 0;
        uint32[] memory totalMiners = new uint32[](CHECK_POINT_HOUR);
        uint32[] memory userMiners = new uint32[](CHECK_POINT_HOUR);
        uint32 ps = start/CHECK_POINT_HOUR*CHECK_POINT_HOUR+CHECK_POINT_HOUR;
        if (ps >= end) {
            
            (income, writeCount) = _collectMinersByCheckPoints(_user, area, start, end, totalMiners, userMiners, writeCount);
            result += income;
        } else {
            
            (income, writeCount) = _collectMinersByCheckPoints(_user, area, start, ps, totalMiners, userMiners, writeCount);
            result += income;

            while (ps < end) {
                (income, writeCount) = _collectMinersByCheckPoints(_user, area, ps, uint32(Math.min64(end, ps + CHECK_POINT_HOUR)), totalMiners, userMiners, writeCount);
                result += income;

                ps += CHECK_POINT_HOUR;
            }
        }
        Collect(_user, area, start, end, result);
        return result;
    }

    function _collectMinersByCheckPoints(address _user, uint32 area, uint32 start, uint32 end, uint32[] memory totalMiners, uint32[] memory userMiners, uint32 _writeCount) internal returns (uint income, uint32 writeCount) {
        //now start from start&#39;s nearest check point
        writeCount = _writeCount;
        income = 0;
        
        
        if (userAreaCheckPoints[_user].hour[start/CHECK_POINT_HOUR*CHECK_POINT_HOUR][area] == 0 && userAreaCheckPoints[_user].hour[start/CHECK_POINT_HOUR*CHECK_POINT_HOUR + CHECK_POINT_HOUR][area] == 0) {
            return;
        }
        _getMinersByCheckPoints(_user, area, start, end, totalMiners, userMiners);
        uint ao = dayAverageOutput[start / 24];
        if (ao == 0) {
            uint32 d = start / 24;
            for (; d >= 0; --d) {
                if (dayAverageOutput[d] != 0) {
                    break;
                }
            } 
            ao = dayAverageOutput[d];
            for (d = d+1; d <= start / 24; ++d) {
                ao = ao*9996/10000;
                if ((start / 24 - d) < writeCount) {
                    dayAverageOutput[d] = ao;
                }
            }
            if (writeCount > (start / 24 - d - 1)) {
                writeCount = writeCount - (start / 24 - d - 1);
            } else {
                writeCount = 0;
            }
        }

        uint week = dayQualitysContract.getAreaQualityByDay(uint32(start * 1 hours + constractDeployTime), area);
        require(week > 0);

        ao = week * ao / 10 / 24 / 72;
        
        income = _getTotalIncomeAt(end - start, userMiners, totalMiners, ao, week);

        if (week == 10) { 
            income = income * 8 / 10;
        } else if (week == 5) { 
            income = income * 6 / 10;
        } 
    }

    function _getTotalIncomeAt(uint32 hourLength, uint32[] memory userMiners, uint32[] memory totalMiners, uint areaOutput, uint week) internal view returns(uint) {
        uint income = 0;
        for (uint i = 0; i < hourLength; ++i) {
            if (userMiners[i] != 0 && totalMiners[i] != 0) {
                income += (Math.min256(10 ** uint256(decimals), areaOutput / totalMiners[i]) * userMiners[i]);
            }
        }
        return income;
    } 

    function _getMinersByCheckPoints(address _user, uint32 area, uint32 start, uint32 end, uint32[] memory totalMiners, uint32[] memory userMiners) internal view {
        require((end - start) <= CHECK_POINT_HOUR);
        //now start from start&#39;s nearest check point
        uint32 h = 0;
        int64 userInc = 0;
        int64 totalInc = 0;
        uint32[3] storage ptUser;
        uint32[3] storage ptArea;
        AreaHourDeployed storage _userAreaHourDeployed = userAreaHourDeployed[_user];
        
        for (h = start/CHECK_POINT_HOUR*CHECK_POINT_HOUR; h <= start; ++h) {
            
            
            
            ptUser = _userAreaHourDeployed.hour[h][area];
            ptArea = areaHourDeployed[h][area];
            totalInc += ptArea[0] + ptArea[1] + ptArea[2] - areaHourDeployed[h - 4][area][0] - areaHourDeployed[h - 8][area][1] - areaHourDeployed[h - 24][area][2];
            userInc += ptUser[0] + ptUser[1] + ptUser[2] - _userAreaHourDeployed.hour[h - 4][area][0] - _userAreaHourDeployed.hour[h - 8][area][1] - _userAreaHourDeployed.hour[h - 24][area][2];
        }

        totalMiners[0] = areaCheckPoints[start/CHECK_POINT_HOUR*CHECK_POINT_HOUR][area] + uint32(totalInc);
        userMiners[0] = userAreaCheckPoints[_user].hour[start/CHECK_POINT_HOUR*CHECK_POINT_HOUR][area] + uint32(userInc);

        uint32 i = 1;
        for (h = start + 1; h < end; ++h) {
            
            
            
            ptUser = _userAreaHourDeployed.hour[h][area];
            ptArea = areaHourDeployed[h][area];
            totalMiners[i] = totalMiners[i-1] + ptArea[0] + ptArea[1] + ptArea[2] - areaHourDeployed[h - 4][area][0] - areaHourDeployed[h - 8][area][1] - areaHourDeployed[h - 24][area][2];
            userMiners[i] = userMiners[i-1] + ptUser[0] + ptUser[1] + ptUser[2] - _userAreaHourDeployed.hour[h - 4][area][0] - _userAreaHourDeployed.hour[h - 8][area][1] - _userAreaHourDeployed.hour[h - 24][area][2];
            ++i;
        }
    }

    
    function withdraw() public {
        uint remain = remainEther[msg.sender]; 
        require(remain > 0);
        remainEther[msg.sender] = 0;

        msg.sender.transfer(remain);
    }

    
    function withdrawMinerFee() public onlyOwner {
        require(amountEther > 0);
        owner.transfer(amountEther);
        amountEther = 0;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function setJewelContract(address jewel) public onlyOwner {
        jewelContract = Jewel(jewel);
    }

    function incise(uint256 value) public returns (uint) {
        require(jewelContract != address(0));

        uint256 balance = balances[msg.sender];
        require(balance >= value);
        uint256 count = (value / (10 ** uint256(decimals)));
        require(count >= 1);

        uint ret = jewelContract.incise(msg.sender, count);

        burn(count * 10 ** uint256(decimals));

        return ret;
    }
}