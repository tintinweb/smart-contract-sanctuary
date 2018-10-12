pragma solidity ^0.4.24;

/**
 * @title Alfa Pet Token
 *
 * @dev Implementation of the ERC223 token.
 */
contract AlfaPetToken {

    /**
    * @dev Contract settings
    */
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public decimalpercent = 1000000;            //precis&#227;o da porcentagem + 2 casas para 100%

    mapping (address => bool) public adminAddress;
    mapping (address => bool) public auditAddress;
    mapping (address => bool) public marketMakerAddress;
    address public mintFeeReceiver;
    address public transferFeeReceiver;
    address public burnFeeReceiver;

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

    constructor(string _name, string _symbol, uint8 _decimals, 
        uint256 _mintFeeAbsMax, uint256 _transferFeeAbsMax, uint256 _burnFeeAbsMax,
        uint256 _mintFeePropMax, uint256 _transferFeePropMax, uint256 _burnFeePropMax
        ) public {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        mintFee.absMax = _mintFeeAbsMax;
        mintFee.propMax = _mintFeePropMax;
        transferFee.absMax = _transferFeeAbsMax;
        transferFee.propMax = _transferFeePropMax;
        burnFee.absMax = _burnFeeAbsMax;
        burnFee.propMax = _burnFeePropMax;
    }

/***********************************************
* @dev Events
************************************************/



/***********************************************
* @dev Modifiers
************************************************/

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


/***********************************************
* @dev AlfaPetToken functions
************************************************/

    /**
    * @notice Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    */
    function mint(address _to, uint256 _amount) internal hasMintPermission (_to) canMint {
        uint256 fee = calcMintFee (_amount);
        uint256 toValue = safeSub(_amount, fee);
        _mint(mintFeeReceiver, fee);
        _mint(_to, toValue);
        _mintApproveClear(_to);
    }

    /**
    * @notice Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _amount The amount to be transferred.
    */
    function transfer(address _to, uint256 _amount) public {
        uint256 fee = calcTransferFee (_amount);
        uint256 toValue = safeSub(_amount, fee);
        _transfer(transferFeeReceiver, fee);
        _transfer(_to, toValue);
    }    
	
    /**
    * @notice Burns a specific amount of tokens.
    * @param _amount The amount of tokens to be burned.
    */
    function burn(uint256 _amount) public hasBurnPermission (_amount) {
        uint256 fee = calcBurnFee (_amount);
        uint256 fromValue = safeSub(_amount, fee);
        _transfer(burnFeeReceiver, fee);
        _burn(msg.sender, fromValue);
        _burnApproveClear(msg.sender);
    }

    function addAdmin(address _address) public onlyOwner {
        adminAddress[_address] = true;
    }    

    function addAudit(address _address) public onlyOwner {
        auditAddress[_address] = true;
    }    

    function addMarketMaker(address _address) public onlyOwner {
        marketMakerAddress[_address] = true;
    }

    function delAdmin(address _address) public onlyOwner {
        adminAddress[_address] = false;        
    }    

    function delAudit(address _address) public onlyOwner {
        auditAddress[_address] = false;        
    }    

    function delMarketMaker(address _address) public onlyOwner {
        marketMakerAddress[_address] = false;        
    }


    function setMintFeeReceiver(address _address) public onlyOwner {
        mintFeeReceiver = _address;
    }

    function setTransferFeeReceiver(address _address) public onlyOwner {
        transferFeeReceiver = _address;
    }    

    function setBurnFeeReceiver(address _address) public onlyOwner {
        burnFeeReceiver = _address;
    }


    function calcMintFee(uint256 _amount) public view returns (uint256) {
        uint256 fee = safeDiv(_amount, decimalpercent);
        fee = safeMul(fee, mintFee.prop);
        fee = safeAdd(fee, mintFee.abs);
        return fee;
    }

    function calcTransferFee(uint256 _amount) public view returns (uint256) {
        uint256 fee = safeDiv(_amount, decimalpercent);
        fee = safeMul(fee, transferFee.prop);
        fee = safeAdd(fee, transferFee.abs);
        return fee;
    }

    function calcBurnFee(uint256 _amount) public view returns (uint256) {
        uint256 fee = safeDiv(_amount, decimalpercent);
        fee = safeMul(fee, burnFee.prop);
        fee = safeAdd(fee, burnFee.abs);
        return fee;
    }


    event SetFee(string action, string typeFee, uint256 value);

    function _setMintFeeAbs(uint256 _value) private onlyOwner {
        mintFee.abs = _value;
        emit SetFee("mint", "absolute", _value);
    }

    function _setMintFeeProp(uint256 _value) private onlyOwner {
        mintFee.prop = _value;
        emit SetFee("mint", "proportional", _value);
    }

    function _setTransferFeeAbs(uint256 _value) private onlyOwner {
        transferFee.abs = _value;
        emit SetFee("transfer", "absolute", _value);
    }    

    function _setTransferFeeProp(uint256 _value) private onlyOwner {
        transferFee.prop = _value;
        emit SetFee("transfer", "proportional", _value);
    }   

    function _setBurnFeeAbs(uint256 _value) private onlyOwner {
        burnFee.abs = _value;
        emit SetFee("burn", "absolute", _value);
    }

    function _setBurnFeeProp(uint256 _value) private onlyOwner {
        burnFee.prop = _value;
        emit SetFee("burn", "proportional", _value);
    }


    event NextFee(string action, string typeFee, uint256 value);

    function nextMintFeeAbs(uint256 _value) public onlyOwner {
        require(_value <= mintFee.absMax, "Value greather then maximum allowed");
        if (mintFee.absNext == _value) {
            mintFee.absNext = 0;
            _setMintFeeAbs (_value);
        }
        else
            mintFee.absNext = _value;
        
        emit NextFee("mint", "absolute", _value);
    }

    function nextMintFeeProp(uint256 _value) public onlyOwner{
        require(_value <= mintFee.propMax, "Value greather then maximum allowed");
        if (mintFee.propNext == _value) {
            mintFee.propNext = 0;
            _setMintFeeProp (_value);
        }
        else
            mintFee.propNext = _value;
        emit NextFee("mint", "proportional", _value);
    }

    function nextTransferFeeAbs(uint256 _value) public onlyOwner {
        require(_value <= transferFee.absMax, "Value greather then maximum allowed");        
        if (transferFee.absNext == _value) {
            transferFee.absNext = 0;
            _setTransferFeeAbs (_value);
        }
        else
            transferFee.absNext = _value;
        emit NextFee("transfer", "absolute", _value);
    }   

    function nextTransferFeeProp(uint256 _value) public onlyOwner {
        require(_value <= transferFee.propMax, "Value greather then maximum allowed");        
        if (transferFee.propNext == _value) {
            transferFee.propNext = 0;
            _setTransferFeeProp (_value);
        }
        else
            transferFee.propNext = _value;
        emit NextFee("transfer", "proportional", _value);
    }   

    function nextBurnFeeAbs(uint256 _value) public onlyOwner {
        require(_value <= burnFee.absMax, "Value greather then maximum allowed");        
        if (burnFee.absNext == _value) {
            burnFee.absNext = 0;
            _setBurnFeeAbs (_value);
        }
        else
            burnFee.absNext = _value;
        emit NextFee("burn", "absolute", _value);
    }

    function nextBurnFeeProp(uint256 _value) public onlyOwner {
        require(_value <= burnFee.propMax, "Value greather then maximum allowed");        
        if (burnFee.propNext == _value) {
            burnFee.propNext = 0;
            _setBurnFeeProp (_value);
        }
        else
            burnFee.propNext = _value;
        emit NextFee("burn", "proportional", _value);
    }


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


    function burnApproveReset(address _address) public onlyOwner {
        _burnApproveClear(_address);
    }

    function _burnApproveClear(address _address) internal {
        burnApprove[_address].amount = 0;
        burnApprove[_address].admin = 0x0;
    }      

    function burnApproval(address _address, uint256 _value) public {
        require((msg.sender == owner) || adminAddress[msg.sender], "Only admin / owner");
        burnApprove[_address].amount = _value;
        burnApprove[_address].admin = msg.sender;
    }

    function burnCancel(address _address) public {
        require(burnApprove[_address].admin == msg.sender, "Only cancel if the address is the same");
        burnApprove[_address].admin = 0x0;
    }
	

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
        require(_account != 0, "Address must be not zero");

        totalSupply_ = safeAdd(totalSupply_, _amount);
        balances[_account] = safeAdd(balances[_account], _amount);
        emit Transfer(address(0), _account, _amount);
        emit Mint(_account, _amount);
    }


    event Burn(address indexed burner, uint256 value);

    modifier hasBurnPermission(uint256 _amount) {
        require(burnApprove[msg.sender].admin != 0x0, "Require admin / owner approval");
        require(burnApprove[msg.sender].amount == _amount, "Amount is different");
        _;
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != 0);
        require(_amount <= balances[_account]);

        totalSupply_ = safeSub(totalSupply_, _amount);
        balances[_account] = safeSub(balances[_account], _amount);
        emit Transfer(_account, address(0), _amount);
        emit Burn(_account, _amount);
    }



    event Transfer(address indexed from, address indexed to, uint256 value);
    //event Transfer(address from, address to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    uint256 private totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public pure returns (bool) {
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public pure returns (bool) {
        return false;
    }


    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
  
    function _transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) private returns (bool success) {
        
        if(isContract(_to)) {
            if (balanceOf(msg.sender) < _value) revert();
            balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
            balances[_to] = safeAdd(balanceOf(_to), _value);

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
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);        
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
  
    function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function safeMul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);
        return c;
    }

    function safeDiv(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); 
        uint256 c = _a / _b;
        return c;
    }

    function safeSub(uint256 _a, uint256 _b) public pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;
        return c;
    }

    function safeAdd(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);
        return c;
    }

    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



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