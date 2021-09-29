//SourceUnit: LMTToken.sol


pragma solidity ^0.5.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract EIP20Interface {
    uint public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
contract Context {
    constructor () internal {}
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
}

contract LMTToken is EIP20Interface,Ownable {
    
    using SafeMath for uint256;
    using Address for address;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    address[] whiteAddress;
    
    address burnAddress = 0x0000000000000000000000000000000000000000;
    address communityAddress = address(0x417D8570E12A817A3F1EF3063FE875BDD94E083F74);
    address foundationAddress = address(0x41FF6AF84BD977A4BEEB6DACA6ED7B09BCC7CDA7F0);
    address lmtPoolAddress = address(0);
    
    //LP contract address
    address private lpContractAddress = address(0);
    uint256 public stopBurn = 3_000_000e6;
    uint256 public burnTotal = 0;
    uint256 public rewardTotal = 0;
    bool public burnSwitch = true;

    string public name ;
    uint8 public decimals;
    string public symbol;

    constructor() public {
        decimals = 6;
        totalSupply = 3_200_000e6;
        balances[communityAddress] = 200_000e6;
        balances[msg.sender] = 3_000_000e6;
        whiteAddress.push(msg.sender);
        name = 'LMT Token';
        symbol = 'LMT';
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
         _transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (allowed[_from][msg.sender] != uint(-1)) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        _transfer(_from, _to, _value);
        return true;
    }
    function _transfer(address _from, address _to, uint256 _value) private {
        bool stopFlag = false;
        for(uint i = 0; i < whiteAddress.length; i++) {
            if(_from == whiteAddress[i] || _to == whiteAddress[i]){
                stopFlag = true;
                break;
            }
        }
        if(burnTotal >= stopBurn){
            stopFlag = true;
        }
        //chech burnSwitch
        if(burnSwitch == false){
            stopFlag = true;
        }
        if(stopFlag){
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(_from, _to, _value);
        }else{
            //deduction fee
            uint256 _fee = _value.div(100).mul(4);
            uint256 _toValue = _value.sub(_fee);
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_toValue);
            emit Transfer(_from, _to, _toValue);
            //burn / reward
            uint256 _feeBurn = _fee.div(100).mul(75);
            uint256 _feeReward = _fee.div(100).mul(25);
            //if exceeded stopBurn
            burnTotal = burnTotal.add(_feeBurn);
            if(burnTotal > stopBurn){
                uint256 diff = burnTotal.sub(stopBurn);
                _feeBurn = _feeBurn.sub(diff);
                burnTotal = stopBurn;
                burnSwitch = false;
                _feeReward = _feeReward.add(diff);
            }
            if(lpContractAddress!=address(0)){
                balances[lpContractAddress] = balances[lpContractAddress].add(_fee);
            }else{
                balances[burnAddress] = balances[burnAddress].add(_feeBurn);
            }
            totalSupply = totalSupply.sub(_feeBurn);
            
            uint256 _feeRewardFoundation = _feeReward.div(100).mul(20);
            uint256 _feeRewardPool = _feeReward.div(100).mul(80);
            balances[lmtPoolAddress] = balances[lmtPoolAddress].add(_feeRewardPool);
            rewardTotal = rewardTotal.add(_feeRewardPool);
            balances[foundationAddress] = balances[foundationAddress].add(_feeRewardFoundation);
            emit Transfer(_from, burnAddress, _feeBurn);
            emit Transfer(_from, lmtPoolAddress, _feeRewardPool);
            emit Transfer(_from, foundationAddress, _feeRewardFoundation);
        }
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    function getRewardTotal() public view returns (uint256) {
        return rewardTotal;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    function setBurnSwitch(bool _switch) public onlyOwner returns (bool success) {
        burnSwitch = _switch;
        return true;
    }
    function setLPContractAddress(address _address) public onlyOwner returns (bool success) {
        lpContractAddress = _address;
        return true;
    }
    
    function setWhiteAddress(address[] memory _addressList) public onlyOwner returns (bool success) {
        for(uint i = 0; i < _addressList.length; i++) {
            whiteAddress.push(_addressList[i]);
        }
        return true;
    }
    function removeWhiteAddress(address _address) public onlyOwner returns (bool success) {
        for(uint i = 0; i < whiteAddress.length; i++) {
            if(_address == whiteAddress[i]){
                delete whiteAddress[i];
                break;
            }
        }
        return true;
    }
    function getWhiteAddress() public onlyOwner view returns (address[] memory) {
        address[] memory list = new address[](whiteAddress.length);
        for(uint i = 0; i < whiteAddress.length; i++) {
            list[i] = whiteAddress[i];
        }
        return list;
    }
    //set pool address 
    function setPoolAddress(address _address) public onlyOwner returns (bool success) {
        lmtPoolAddress = _address;
        return true;
    }
    
}