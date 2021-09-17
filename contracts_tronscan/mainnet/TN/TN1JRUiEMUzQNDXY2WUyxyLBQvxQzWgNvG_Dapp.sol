//SourceUnit: Award.sol

pragma solidity 0.5.10;

// pragma experimental ABIEncoderV2;

import "./Basic.sol";
import "./DataStorage.sol";
import "./DataStorageOp.sol";
import "./TetherToken.sol";
import "./Dapp.sol";

contract Award is DataStorageOp {
    using SafeMath for uint;

    constructor() public {

    }

    function doHelp(uint _value) public payable {
        Dapp main = Dapp(sysAddress['main']);
        //最大帮助限制
        require(_value <= main.sysInt('maxInvest'), 'errmax value 5000err');
        //必须开启
        require(main.sysInt('insureOpen') + main.sysInt('roundc') >= now, 'errinsuremustopenerr');
        //立即帮助完成
        require( (sysInt['help'] + _value) * 2 <= main.sysInt('insureValue'), 'errhelpdoneerr' );
        
        TetherToken usdt = TetherToken(sysAddress['usdt']);
        require(usdt.allowance(msg.sender, address(this)) >= _value , 'errusdtallowerr');
        //获取usdt
        require(usdt.balanceOf(msg.sender) >= _value, 'errusdtInsufficienterr');
        //只能帮助一次
        require(userStringInt[msg.sender]['help'] == 0, 'errhave helperr');


        usdt.transferFrom(msg.sender, sysAddress['main'], _value);
        
        userStringInt[msg.sender]['help'] = _value;
        sysInt['help'] += _value;
        if (sysInt['help'] * 2 >= main.sysInt('insureValue')) {
            main.setSysInt('insureValue', 0);
            // sysInt['help'] = 0;
        }
    }

    function getHelp() public {
        Dapp main = Dapp(sysAddress['main']);
        require(userStringInt[msg.sender]['help'] > 0, 'errusdtInsufficienterr');
        require(main.sysInt('insureOpen') + main.sysInt('roundc') < now, 'errinsuremustovererr');
        TetherToken usdt = TetherToken(sysAddress['usdt']);
        uint can_tmp = 0;
        can_tmp = userStringInt[msg.sender]['help'];
        sysInt['help'] = sysInt['help'].sub( can_tmp );
        userStringInt[msg.sender]['help'] = 0;
        usdt.transfer(msg.sender, can_tmp * 2);
        if(main.sysInt('insureOpen') > 0) {
            main.setSysInt('insureOpen', 0);
        }
    }
}


//SourceUnit: Basic.sol

pragma solidity 0.5.10;


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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    constructor() public {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner, 'erronlyOwnererr');
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint;
    mapping(address => uint) public balances;

    // additional variables for use if transaction fees ever became necessary
    uint public basisPointsRate = 0;
    uint public maximumFee = 0;

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint sendAmount = _value.sub(fee);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(msg.sender, owner, fee);
        }
        emit Transfer(msg.sender, _to, sendAmount);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) public allowed;

    uint public constant MAX_UINT = 2**256 - 1;

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        uint _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        uint sendAmount = _value.sub(fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(_from, owner, fee);
        }
        emit Transfer(_from, _to, sendAmount);
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    /**
    * @dev Function to check the amount of tokens than an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract BlackList is Ownable, BasicToken {

    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}

contract UpgradedStandardToken is StandardToken{
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    function transferByLegacy(address from, address to, uint value) public;
    function transferFromByLegacy(address sender, address from, address spender, uint value) public;
    function approveByLegacy(address from, address spender, uint value) public;
}

contract addrTool {
    function addressToString(address _addr) public pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '4';
        str[1] = '1';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }
}

contract burnAble {
    event Burn(address indexed from, uint256 value);
}


//SourceUnit: Dapp.sol

pragma solidity 0.5.10;

// pragma experimental ABIEncoderV2;

import "./Basic.sol";
import "./DataStorage.sol";
import "./DataStorageOp.sol";
import "./TetherToken.sol";

contract Dapp is DataStorageOp {
    using SafeMath for uint;

    constructor() public {
        init();
    }

    function init() internal {
        if(sysInt['init'] == 1) {
            return;
        }
        sysInt['init'] = 1;

        sysInt['init_time'] = now;

        sysInt['minInvest'] = 100000000;
        sysInt['firstMax'] = 1000000000;
        sysInt['maxInvest'] = 5000000000;
      
        sysInt['platformFee'] = 50;
       
        sysInt['insureFee'] = 20;

        sysInt['feeBase'] = 1000;
        
        sysInt['fee'] = 0;

        sysAddress['fee'] = address(0);
        
        sysAddress['award'] = address(0);
  
        sysInt['dayRate'] = 12;
        sysInt['roundRate'] = 12 * 15;
        sysInt['maxDep'] = 10;

        sysInt['rounda'] = 24 * 60 * 60;
        
        sysInt['roundb'] = 24 * 60 * 60 * 15;
        
        sysInt['roundc'] = 24 * 60 * 60;
    
        sysUintArray['rate'] = [150,300,500,50,50,50,50,50,50,50,10,10,10,10,10];

        sysInt['maxId'] = 1;

        sysInt['insureOpen'] = 0;
    }

    function invest(address referrer, uint _value) public payable {
        require(_value <= sysInt['maxInvest'], 'errmax value 5000err');
        require(_value <= sysInt['firstMax'] * (userStringInt[msg.sender]['investCount'] + 1), 'errmax2err');

        require(sysInt['insureOpen'] + sysInt['roundc'] < now, 'errinsuremustcloseerr');
        require(_value / 10000000 * 10000000 == _value, 'errvalue10err');

        TetherToken usdt = TetherToken(sysAddress['usdt']);
        require(usdt.allowance(msg.sender, address(this)) >= _value , 'errusdtallowerr');

        require(usdt.balanceOf(msg.sender) >= _value, 'errusdtInsufficienterr');
        require(sysAddress['award'] != address(0), 'erraward addresserr');
        require(sysAddress['fee'] != address(0), 'errfee addresserr');

        usdt.transferFrom(msg.sender, address(this), _value);
        //平台费
        usdt.transfer(sysAddress['fee'], _value * sysInt['platformFee'] / sysInt['feeBase']);
        sysInt['fee'] += _value * sysInt['platformFee'] / sysInt['feeBase'];
        //保险费
        usdt.transfer(sysAddress['award'], _value * sysInt['insureFee'] / sysInt['feeBase']);

        if( userStringInt[msg.sender]['invest'] == 0 ) {
            require(referrer != msg.sender, 'erruplineerr');
            require(_value >= sysInt['minInvest'], 'errmin value 100err');
            //推荐人投入必须大于 0
            require(userStringInt[referrer]['invest'] > 0 || referrer == owner, 'errupline not existerr');

            userStringAddress[msg.sender]['referrer'] = referrer;
            userStringInt[msg.sender]['investCount'] = 1;
            userStringInt[msg.sender]['id'] = sysInt['maxId'];

            sysUintAddress['idToAddress'][sysInt['maxId']] = msg.sender;

            sysInt['maxId']++;

            userStringInt[referrer]['count'] += 1;
            userStringInt[msg.sender]['team'] = 0;
            userStringInt[msg.sender]['count'] = 0;

            //推荐关系
            userStringAddressArray[referrer]['childs'].push(msg.sender);
        }else{
            require(userStringInt[msg.sender]['start'] + sysInt['roundb'] <= now, 'errtimelimiterr');
            //复投 结算上期进可提现
            require(_value >= userStringInt[msg.sender]['invest'], 'errmust big then lasterr');
            uint income = userStringInt[msg.sender]['invest'] * sysInt['roundRate'] / sysInt['feeBase'];
            userStringInt[msg.sender]['static'] += income;
            userStringInt[msg.sender]['canwithdraw'] += userStringInt[msg.sender]['invest'] + income;
            //未提现标记
            userStringInt[msg.sender]['investsum'] += userStringInt[msg.sender]['invest'];
            userStringInt[msg.sender]['staticsum'] += income;
            // userStringInt[msg.sender]['awardsum'] += userStringInt[msg.sender]['canwithdrawaward'];

            //结算动态奖
            // userStringInt[msg.sender]['canwithdraw'] += userStringInt[msg.sender]['canwithdrawaward'];
            // userStringInt[msg.sender]['canwithdrawaward'] = 0;
            // userStringInt[msg.sender]['canwithdraw'] += userStringInt[msg.sender]['awardsum'];

            userStringInt[msg.sender]['investCount']++; 
        }
        userStringInt[msg.sender]['invest'] = _value;
        //推荐奖
        doAward(msg.sender, userStringAddress[msg.sender]['referrer'], 0);
        userStringInt[msg.sender]['start'] = now;
                
        userStringIntArray[msg.sender]['his_time'].push(now);
        userStringIntArray[msg.sender]['his_invest'].push(_value);
    }

    function doAward(address addr, address referrer, uint dep) private {
        //最大深度限制
        if(dep < sysInt['maxDep']) {
            if(userStringInt[addr]['investCount'] == 1) {
                userStringInt[referrer]['team'] += 1;
            }
            //推广几人拿几代
            if(userStringInt[referrer]['count'] > dep) {
                uint invest_tmp = userStringInt[addr]['invest'];
                //烧伤
                if(userStringInt[addr]['invest'] > userStringInt[referrer]['invest']) {
                    invest_tmp = userStringInt[referrer]['invest'];
                }

                uint award_tmp = invest_tmp * sysInt['roundRate'] / sysInt['feeBase'] * sysUintArray['rate'][dep] / sysInt['feeBase'];

                // userStringInt[referrer]['canwithdrawaward'] += award_tmp;
                userStringInt[referrer]['awardsum'] += award_tmp;
                userStringInt[referrer]['dynamic'] += award_tmp;
            }

            if(userStringAddress[referrer]['referrer'] != address(0) && userStringAddress[referrer]['referrer'] != owner) {
                doAward(addr, userStringAddress[referrer]['referrer'], dep + 1);
            }
        }
    }
    
    function withdraw() public {
        TetherToken usdt = TetherToken(sysAddress['usdt']);
        uint can_tmp = 0;

        //普通提现
        require(userStringInt[msg.sender]['canwithdraw'] > 0, 'errcanwithdraw must > 0err');
        require(usdt.balanceOf(address(this)) > 0, 'errdappUsdtInsufficienterr');
        can_tmp = userStringInt[msg.sender]['canwithdraw'] + userStringInt[msg.sender]['awardsum'];
        if(can_tmp > usdt.balanceOf(address(this)) ) {
            can_tmp = usdt.balanceOf(address(this));
            //开启保险
            sysInt['insureOpen'] = now;
            sysInt['insureValue'] = usdt.balanceOf(sysAddress['award']);
            if(can_tmp > userStringInt[msg.sender]['canwithdraw']) {
                userStringInt[msg.sender]['canwithdraw'] = 0;
                userStringInt[msg.sender]['awardsum'] = can_tmp - userStringInt[msg.sender]['canwithdraw'];
            }else{
                userStringInt[msg.sender]['canwithdraw'] = userStringInt[msg.sender]['canwithdraw'] - can_tmp;
            }
        }else{
            userStringInt[msg.sender]['canwithdraw'] = 0;
            userStringInt[msg.sender]['awardsum'] = 0;
        }

        userStringInt[msg.sender]['take'] += can_tmp;
        usdt.transfer(msg.sender, can_tmp);

        //未提标识
        userStringInt[msg.sender]['investsum'] = 0;
        userStringInt[msg.sender]['staticsum'] = 0;
    }
}


//SourceUnit: DataStorage.sol

 
pragma solidity 0.5.10;

import "./Basic.sol";

contract DataStorage is Ownable {
    //被代理的业务合约地址
    address internal proxied;

    mapping(string => uint) public sysInt;
    mapping(string => address) public sysAddress;
    mapping(string => uint[]) public sysUintArray;
    mapping(string => address[]) public sysAddressArray;
    mapping(string => mapping(uint => address)) public sysUintAddress;
    mapping(string => mapping(uint => uint)) public sysUintUint;
    mapping(string => mapping(address => uint)) public sysAddressUint;

    mapping(address => mapping(string => uint)) public userStringInt;
    mapping(address => mapping(string => uint[])) public userStringIntArray;
    mapping(address => mapping(string => address)) public userStringAddress;
    mapping(address => mapping(string => address[])) public userStringAddressArray;
}

//SourceUnit: DataStorageOp.sol

 
pragma solidity 0.5.10;

import "./Basic.sol";
import "./DataStorage.sol";

contract DataStorageOp is DataStorage {

    modifier onlyOwnerOrKeeper() {
        require(msg.sender == owner || sysAddressUint['keeper'][msg.sender] == 1, "errOwnable: caller is not the owner or keeper.err");
        _;
    }

    function setSysInt(string memory param, uint value) public onlyOwnerOrKeeper {
        sysInt[param] = value;
    }

    function setSysAddress(string memory param, address value) public onlyOwnerOrKeeper {
        sysAddress[param] = value;
    }

    // function setSysUintArray(string memory param, uint key, uint value) public onlyOwnerOrKeeper {
    //     sysUintArray[param][key] = value;
    // }

    // function setSysAddressArray(string memory param, uint key, address value) public onlyOwnerOrKeeper {
    //     sysAddressArray[param][key] = value;
    // }

    // function setSysUintAddress(string memory param, uint key, address value) public onlyOwnerOrKeeper {
    //     sysUintAddress[param][key] = value;
    // }

    // function setSysUintUint(string memory param, uint key, uint value) public onlyOwnerOrKeeper {
    //     sysUintUint[param][key] = value;
    // }

    function setSysAddressUint(string memory param, address key, uint value) public onlyOwnerOrKeeper {
        sysAddressUint[param][key] = value;
    }

    // function setUserStringInt(address _user, string memory param, uint value) public onlyOwnerOrKeeper {
    //     userStringInt[_user][param] = value;
    // }

    // function setUserStringIntArray(address _user, string memory param, uint key, uint value) public onlyOwnerOrKeeper {
    //     userStringIntArray[_user][param][key] = value;
    // }

    // function setUserStringAddress(address _user, string memory param, address value) public onlyOwnerOrKeeper {
    //     userStringAddress[_user][param] = value;
    // }

    // function setUserStringAddressArray(address _user, string memory param, uint key, address value) public onlyOwnerOrKeeper {
    //     userStringAddressArray[_user][param][key] = value;
    // }
}

//SourceUnit: Events.sol


pragma solidity 0.5.10;


contract Events {
  event Registration(address member, uint memberId, address sponsor, uint orderId);
  event Upgrade(address member, address sponsor, uint system, uint level, uint orderId);
}

//SourceUnit: Migrations.sol

pragma solidity ^0.5.10;

contract Migrations {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
}



//SourceUnit: TetherToken.sol

pragma solidity ^0.5.10;


contract TetherToken {
    function transfer(address _to, uint _value) public returns (bool);
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint);
    function balanceOf(address who) public view returns (uint);
}