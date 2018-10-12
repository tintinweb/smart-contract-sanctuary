pragma solidity ^0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3e5a5f485b7e5f5551535c5f105d5153">[email&#160;protected]</a>
// released under Apache 2.0 licence
contract Ownable {
    
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(msg.sender == owner);
        _;
    }


    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
      if (a == 0) {
        return 0;
      }
      c = a * b;
      assert(c / a == b);
      return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      // assert(b > 0); // Solidity automatically throws when dividing by 0
      // uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
      return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
      c = a + b;
      assert(c >= a);
      return c;
    }
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract ERC223 is Ownable {
    /**
     * token名称（Krypton）
     */
    function name() public pure returns (string);
    /**
     * token标识（KR）
     */
    function symbol() public pure returns (string);
    /**
     * token小数点位数（2位）
     */
    function decimals() public pure returns (uint8);
    /**
     * token发行总量 1000000000
     */
    function totalSupply() public view returns (uint256);
    /**
     * 获取账户余额
     */
    function balanceOf(address _owner) public view returns (uint256);
    /**
     * 发送token给指定账户(等同于ERC20)；向非合约账户支付，可以采用这个接口。
     */
    function transfer(address _to, uint256 _value) public returns (bool);
    /**
     * 发送token给指定账户
     * data参数：交易记录中记录的附加数据（需要有支付的合约继承ContractReceiver，进行回调处理）
     */
    function transferWithData(address _to, uint256 _value, bytes data) public returns (bool);
    /**
     * 发送token给指定账户，并设置部分token冻结时间与数量
     */
    function transferAndFrozen(address _to, uint256 _value, bytes _data, uint256 _days, uint256 _frozenCount) public returns(bool);

    /**
     * 发送token，同时，指定冻结时间与数量
     */
    function frozenControl(address _addr, uint256 _days, uint256 _count) public;

    /**
     * 解冻部分或全部被冻结Token
     */
    function unFrozenControl(address _addr, uint256 _count) public;

    /**
     * 销毁token
     */
    function burn(uint256 _value) public returns (bool);

    /**
     * 查看冻结地址总冻结数量
     */
    function sumOfFreezing(address _addr) public view returns (uint256 count);

    /**
     * 控制是否可以用户间自由交易（false-不可以 true-可以）
     */
    function transferControl(bool flag) public;

    /**
     * 销毁合约
     */
    function destroy() public;

    event Transfer(address indexed from, address indexed to, uint value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address addr, uint256 fdays);
}

interface ContractReceiver  {function  tokenFallback(address _from, uint _value, bytes _data) external;}

contract KRToken is ERC223 {

    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    string public constant tokenName = "krypton";
    string public constant tokenSymbol = "KR";
    uint8  public constant  tokenDecimals = 2;
    uint256 public initialSupply = 1000000000;
    uint256 public tokenTotalSupply;

    bool public freeTransferFlag = false;               // The flag only owner can transfer token at beginning.
    // True it can transfer between accounts; Or only owner.


    struct FrozenInfo {
        bool erased;        // is it erased from the array?
        uint32 fdays;       // freezing token days.
        uint32 count;       // freezing token count.
    }

    // Frozen account in time. if uint == 1 then frozen account forever, before contract owner unlock manually.
    mapping (address => FrozenInfo[]) public freezes;


    // Function to access name of token .
    function name() public pure returns (string) {
        return tokenName;
    }
    // Function to access symbol of token .
    function symbol() public pure returns (string) {
        return tokenSymbol;
    }
    // Function to access decimals of token .
    function decimals() public pure returns (uint8) {
        return tokenDecimals;
    }
    // Function to access total supply of tokens .
    function totalSupply() public view returns (uint256) {
        return tokenTotalSupply;
    }

    // Constructor Function to intialize token to contractor woner.
    constructor() public {
        tokenTotalSupply = initialSupply * 10 ** uint256(tokenDecimals);
        balances[msg.sender] = tokenTotalSupply;
    }

    // Function control free transfer flag.
    function transferControl(bool flag) public onlyOwner {
        freeTransferFlag = flag;
    }

    function _canNowTransfer() private view returns (bool){
        if (!freeTransferFlag)
        {
            if(msg.sender == owner) {
                return true;
            }
            return false;
        }

        return true;
    }



    // Function that is called when a user or another contract wants to transfer funds .
    function transferWithData(address _to, uint256 _value, bytes _data) public returns (bool) {
        require(_to != address(0));
        if(!_canNowTransfer()) {
            revert();
        }

        if(_isContract(_to)) {
            return _transferToContract(_to, _value, _data);
        }
        else {
            return _transferToAddress(_to, _value);
        }
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint256 _value) public returns (bool) {
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        require(_to != address(0));
        if(!_canNowTransfer()) {
            revert();
        }

        bytes memory empty;
        if(_isContract(_to)) {
            return _transferToContract(_to, _value, empty);
        }
        else {
            return _transferToAddress(_to, _value);
        }
    }

    // function to transfer some token and make some token to be freezing.
    function transferAndFrozen(address _to, uint256 _value, bytes _data, uint256 _days, uint256 _frozenCount) public onlyOwner returns(bool) {
        require(_to != address(0));
        bool ret = true;
        if(_isContract(_to)) {
            ret = _transferToContract(_to, _value, _data);
        }
        else {
            ret = _transferToAddress(_to, _value);
        }

        frozenControl(_to, _days, _frozenCount);

        return ret;
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function _isContract(address _addr) private view returns (bool) {
        uint length;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }

    //function that is called when transaction target is an address
    function _transferToAddress(address _to, uint256 _value) private returns (bool) {
        require(balanceOf(msg.sender) >= _value);
        require(balanceOf(_to).add(_value) >= balanceOf(_to));


        // Make sure to subtract freezing token.
        uint256 freezingCount;
        FrozenInfo[] storage infos = freezes[msg.sender];
        if(infos.length > 0) {
            for (uint i=0; i<infos.length; i++) {
                FrozenInfo storage info = infos[i];
                if(!info.erased) {
                    if (info.fdays > now) {
                        freezingCount = freezingCount.add(info.count);
                    } else {
                        delete infos[i];
                        infos[i].erased = true;
                    }
                }
            }
        }
        require(balanceOf(msg.sender).sub(freezingCount) >= _value);

        uint previousBalances = balanceOf(msg.sender).add(balanceOf(_to));

        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        emit Transfer(msg.sender, _to, _value);

        assert(balanceOf(msg.sender).add(balanceOf(_to)) == previousBalances);
        return true;
    }

    //function that is called when transaction target is a contract
    function _transferToContract(address _to, uint256 _value, bytes _data) private returns (bool) {
        require(balanceOf(msg.sender) >= _value);
        require(balanceOf(_to).add(_value) >= balanceOf(_to));

        // Make sure to subtract freezing token.
        uint256 freezingCount;
        FrozenInfo[] storage infos = freezes[msg.sender];
        if(infos.length > 0) {
            for (uint i=0; i<infos.length; i++) {
                FrozenInfo storage info = infos[i];
                if(!info.erased) {
                    if (info.fdays > now) {
                        freezingCount = freezingCount.add(info.count);
                    } else {
                        delete infos[i];
                        infos[i].erased = true;
                    }
                }
            }
        }
        require(balanceOf(msg.sender).sub(freezingCount) >= _value);

        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

    // function to burn some tokens.
    function burn(uint256 _value) public onlyOwner returns (bool) {
        require(balanceOf(msg.sender) >= _value);
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        tokenTotalSupply = tokenTotalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    // function to freeze a address for days.
    function frozenControl(address _addr, uint256 _days, uint256 _count) public onlyOwner {
        require(_addr != address(0));
        // need have enough token.
        require(balanceOf(_addr) - sumOfFreezing(_addr) >= _count);
        if(_days == 0) {
            revert();
        }

        bool freeused = false;
        FrozenInfo[] storage infos = freezes[_addr];
        for(uint i=0; i<infos.length; i++) {
            if(infos[i].erased) {
                infos[i].erased = false;
                infos[i].count = uint32(_count);
                infos[i].fdays = uint32(now + _days * 1 minutes);
                freeused = true;
                break;
            }
        }
        if(!freeused) {
            infos.push(FrozenInfo(false, uint32(now + _days * 1 minutes), uint32(_count)));
        }

        emit Freeze(_addr, _days);
    }

    function unFrozenControl(address _addr, uint256 _count) public onlyOwner {
        require(sumOfFreezing(_addr) >= _count);

        uint leafCount = _count;

        FrozenInfo[] storage infos = freezes[_addr];
        if(infos.length > 0) {
            for (uint i=0; i <infos.length; i++) {
                if(leafCount <= 0) {
                    break;
                }
                FrozenInfo storage info = infos[i];
                if (info.fdays > now) {
                    if(info.count > leafCount)  {
                        assert(leafCount <= info.count);
                        info.count = info.count - uint32(leafCount);
                        leafCount = 0;
                        break;
                    } else {
                        leafCount = leafCount.sub(info.count);
                        delete infos[i];
                        infos[i].erased = true;
                    }
                }
            }
        }
    }


    // function calculate the sum of the token
    function sumOfFreezing(address _addr) public view returns (uint256 count) {

        FrozenInfo[] storage infos = freezes[_addr];
        if(infos.length <= 0) {
            return 0;
        }
        uint256 sum = 0;
        for(uint256 i=0; i<infos.length; i++) {
            if(!infos[i].erased) {
                sum = sum.add(infos[i].count);
            }
        }

        return sum;
    }

    function destroy() public onlyOwner {
        selfdestruct(msg.sender);
    }

}