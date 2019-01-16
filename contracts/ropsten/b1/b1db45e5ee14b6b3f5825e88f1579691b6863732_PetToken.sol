pragma solidity 0.4.24;


//import "./SafeMath.sol";
//file: ./SafeMath.sol;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 * from OpenZeppelin
 * https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/master/contracts/math/SafeMath.sol
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract PetToken {
    using SafeMath for uint256;

    address public owner;
    address public ownerMaster;
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping (address => bool) public adminAddress;
    mapping (address => bool) public auditAddress;
    mapping (address => bool) public marketMakerAddress;
    address public mintFeeReceiver;
    address public transferFeeReceiver;
    address public burnFeeReceiver;

    uint256 public decimalpercent = 1000000;            //precis&#227;o da porcentagem + 2 casas para 100%   
    struct feeStruct {        
        uint256 abs;
        uint256 prop;
        uint256 absMax;
        uint256 propMax;
        uint256 absNext;
        uint256 propNext;
    }
    feeStruct public mintFee;
    feeStruct public transferFee;
    feeStruct public burnFee;

    struct approveMintStruct {        
        uint256 amount;
        address admin;
        address audit;
        address marketMaker;
    }
    mapping (address => approveMintStruct) public mintApprove;

    struct approveBurnStruct {
        uint256 amount;
        address admin;
    }    
    mapping (address => approveBurnStruct) public burnApprove;

    uint256 transferFrequency;
    uint256 transferMaxAmount;
    bool speedBump;


    constructor(string _name, string _symbol, uint8 _decimals,
            //uint256 _mintFeeAbsMax, uint256 _mintFeePropMax, uint256 _transferFeeAbsMax, uint256 _transferFeePropMax,
            address _ownerMaster
        ) public {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        /*
        mintFee.absMax = _mintFeeAbsMax;
        mintFee.propMax = _mintFeePropMax;
        transferFee.absMax = _transferFeeAbsMax;
        transferFee.propMax = _transferFeePropMax;
        */
        ownerMaster = _ownerMaster;

        balances[msg.sender] = 10000;
        totalSupply_ = 10000;

        mintFeeReceiver = 0x27D748CCCc0ba475b2A11211e634073F94633d98;         //account04
        transferFeeReceiver = 0x9BD83476b917Db14a134b040665423B1593Ebf16;     //account05
        mintFee.abs = 3;
        mintFee.prop = 0;
        transferFee.abs = 1;
        transferFee.prop = 0;
    }

    /**
    * @dev Modifiers
    */
    modifier onlyAdmin() {
        require(adminAddress[msg.sender], "Only admin");
        _;
    }

    modifier onlyAudit() {
        require(auditAddress[msg.sender], "Only audit");
        _;
    }

    modifier onlyMarketMaker() {
        require(marketMakerAddress[msg.sender], "Only market maker");
        _;
    }


    /**
    * @dev AlfaPetToken functions
    */
    function mint(address _to, uint256 _amount) public canMint {
        uint256 fee = calcMintFee (_amount);
        uint256 toValue = _amount.sub(fee);
        _mint(mintFeeReceiver, fee);
        _mint(_to, toValue);
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        uint256 fee = calcTransferFee (_amount);
        uint256 toValue = _amount.sub(fee);
        _transfer(transferFeeReceiver, fee);
        _transfer(_to, toValue);
        return true;
    }


    /**
    * @dev Address roles
    */
    function addAdminAddress(address _address) public onlyOwner returns (bool) {
        adminAddress[_address] = true;
        return true;
    }    

    function addAuditAddress(address _address) public onlyOwner returns (bool) {
        adminAddress[_address] = true;
        return true;
    }  

    function addMarketMakerAddress(address _address) public onlyOwner returns (bool) {
        marketMakerAddress[_address] = true;
        return true;
    }

    function delAdminAddress(address _address) public onlyOwner returns (bool) {
        adminAddress[_address] = false;
        return true;
    }

    function delAuditAddress(address _address) public onlyOwner returns (bool) {
        adminAddress[_address] = false;
        return true;
    }

    function delMarketMakerAddress(address _address) public onlyOwner returns (bool) {
        marketMakerAddress[_address] = false;
        return true;
    }


    /**
    * @dev Address Fees receivers
    */
    function setMintFeeReceiver(address _address) public onlyOwner returns (bool) {
        mintFeeReceiver = _address;
        return true;
    }

    function setTransferFeeReceiver(address _address) public onlyOwner returns (bool) {
        transferFeeReceiver = _address;
        return true;
    }    


    /*
    * @dev Calc Fees
    */
    function calcMintFee(uint256 _amount) public view returns (uint256) {
        uint256 fee = 0;
        fee = _amount.div(decimalpercent);
        fee = fee.mul(mintFee.prop);
        fee = fee.add(mintFee.abs);
        return fee;
    }

    function calcTransferFee(uint256 _amount) public view returns (uint256) {
        uint256 fee = 0;
        fee = _amount.div(decimalpercent);
        fee = fee.mul(transferFee.prop);
        fee = fee.add(transferFee.abs);
        return fee;
    }


    /**
    * @dev Set Fees
    */
    event SetFee(string action, string typeFee, uint256 value);

    function setMintFeeAbs(uint256 _value) external onlyOwner returns (bool) {
        require(_value < mintFee.absMax, "Must be less then maximum");
        mintFee.abs = _value;
        emit SetFee("mint", "absolute", _value);
        return true;
    }

    function setTransferFeeAbs(uint256 _value) external onlyOwner returns (bool) {
        require(_value < transferFee.absMax, "Must be less then maximum");
        transferFee.abs = _value;
        emit SetFee("transfer", "absolute", _value);
        return true;
    }

    function setMintFeeProp(uint256 _value) external onlyOwner returns (bool) {
        require(_value < mintFee.propMax, "Must be less then maximum");
        mintFee.prop = _value;
        emit SetFee("mint", "proportional", _value);
        return true;
    }
 
    function setTransferFeeProp(uint256 _value) external onlyOwner returns (bool) {
        require(_value < transferFee.propMax, "Must be less then maximum");
        transferFee.prop = _value;
        emit SetFee("transfer", "proportional", _value);
        return true;
    }
        

    /**
    * @dev Ownable 
    * ownerMaster can not be changed.
    */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);    

    modifier onlyOwner() {
        require((msg.sender == owner) || (msg.sender == ownerMaster), "Only owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "newOwner must be not 0x0");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    
    /*
    * @dev Mint Approval
    */
    function mintApproveReset(address _address) public onlyOwner {
        _mintApproveClear(_address);
    }

    function _mintApproveClear(address _address) internal {
        mintApprove[_address].amount = 0;
        mintApprove[_address].admin = 0x0;
        mintApprove[_address].audit = 0x0;
        mintApprove[_address].marketMaker = 0x0;
    }

    function mintAdminApproval(address _address, uint256 _value) public onlyAdmin {
        if (mintApprove[_address].amount > 0) {
            require(mintApprove[_address].amount == _value, "Value is diferent");
        }
        else {
            mintApprove[_address].amount = _value;
        }        
        mintApprove[_address].admin = msg.sender;
        
        if ((mintApprove[_address].audit != 0x0) && (mintApprove[_address].marketMaker != 0x0))
            mint(_address, _value);
    }

    function mintAdminCancel(address _address) public onlyAdmin {
        require(mintApprove[_address].admin == msg.sender, "Only cancel if the address is the same admin");
        mintApprove[_address].admin = 0x0;
    }

    function mintAuditApproval(address _address, uint256 _value) public onlyAudit {
        if (mintApprove[_address].amount > 0) {
            require(mintApprove[_address].amount == _value, "Value is diferent");
        }
        else {
            mintApprove[_address].amount = _value;
        }        
        mintApprove[_address].audit = msg.sender;

        if ((mintApprove[_address].admin != 0x0) && (mintApprove[_address].marketMaker != 0x0))
            mint(_address, _value);
    }

    function mintAuditCancel(address _address) public onlyAudit {
        require(mintApprove[_address].audit == msg.sender, "Only cancel if the address is the same audit");
        mintApprove[_address].audit = 0x0;
    }

    function mintMarketMakerApproval(address _address, uint256 _value) public onlyMarketMaker {
        if (mintApprove[_address].amount > 0) {
            require(mintApprove[_address].amount == _value, "Value is diferent");
        }
        else {
            mintApprove[_address].amount = _value;
        }        
        mintApprove[_address].marketMaker = msg.sender;

        if ((mintApprove[_address].admin != 0x0) && (mintApprove[_address].audit != 0x0))
            mint(_address, _value);
    }

    function mintMarketMakerCancel(address _address) public onlyMarketMaker {
        require(mintApprove[_address].marketMaker == msg.sender, "Only cancel if the address is the same marketMaker");
        mintApprove[_address].marketMaker = 0x0;
    }

	
    /**
    * @dev Mintable token
    */
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished, "Mint is finished");
        _;
    }

    modifier hasMintPermission(address _address) {
        require(mintApprove[_address].admin != 0x0, "Require admin approval");
        require(mintApprove[_address].audit != 0x0, "Require audit approval");
        require(mintApprove[_address].marketMaker != 0x0, "Require market maker approval");        
        _;
    }

    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != 0, "Address must not be zero");
        totalSupply_ = totalSupply_.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
        emit Mint(_account, _amount);
    }


    /**
    * @dev Standard ERC20 token
    */
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    uint256 private totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);    


    /**
    * @dev ERC223 token
    */
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
  
    function _transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) private returns (bool success) {                
        if (isContract(_to)) {
            if (balanceOf(msg.sender) < _value) revert("Insuficient funds");
            balances[msg.sender] = balanceOf(msg.sender).sub(_value);
            balances[_to] = balanceOf(_to).add(_value);
            assert(_to.call.value(0)(bytes4(keccak256(abi.encodePacked(_custom_fallback))), msg.sender, _value, _data));
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function _transfer(address _to, uint256 _value, bytes _data) private returns (bool success) {            
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function _transfer(address _to, uint256 _value) private returns (bool success) {            
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value, empty);
        }
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint codeLength;
        assembly {
            codeLength := extcodesize(_addr)
        }
        return (codeLength>0);
    }

    function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);        
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
  
    function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

}


/**
* @dev Contract that is working with ERC223 tokens.
*/
contract ContractReceiver {     
    struct TKN {
        address sender;
        uint256 value;
        bytes data;
        bytes4 sig;
    }    
    
    function tokenFallback(address _from, uint256 _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);
    }
}