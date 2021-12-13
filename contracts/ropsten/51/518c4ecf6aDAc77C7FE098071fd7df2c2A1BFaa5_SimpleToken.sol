/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

abstract contract OwnerHelper {
    address[3] private _owners;
    address private _genesisOwner;
    uint private _numOwners;

    struct AgreementData{
        bool yesno;
        string functionCode;
        uint[] parameters;
        string comment;
    }

    AgreementData[3] internal ownerAgreements;

    event OwnershipTransferred(address indexed preOwner, address indexed nextOwner);

    modifier isGenesisOwner {
        require(msg.sender == _genesisOwner, "OwnerHelper: caller not contract creator");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == _owners[0] || msg.sender == _owners[1] || msg.sender == _owners[2], "OwnerHelper: caller is not one of owners");
        _;
    }

    modifier agreementOnly(){
        if (_numOwners == 2){
            require(bytes(ownerAgreements[0].functionCode).length > 0 && bytes(ownerAgreements[1].functionCode).length > 0, "Agreement not set");
            require(ownerAgreements[0].yesno == ownerAgreements[1].yesno, "Opinions Do Not Match");
            require(keccak256(bytes(ownerAgreements[0].functionCode)) == keccak256(bytes(ownerAgreements[1].functionCode)), "Functions Do Not Match");
            require(ownerAgreements[0].parameters.length == ownerAgreements[1].parameters.length, "Parameter size do not match");

            for (uint i=0; i<ownerAgreements[0].parameters.length; i++){
                require(ownerAgreements[0].parameters[i] == ownerAgreements[1].parameters[i], "Function Parameters Do Not Match");
            }

            //require(keccak256(bytes(ownerAgreements[0].decision)) == keccak256(bytes(ownerAgreements[1].decision)), "Decision Parameters Do Not Match");
        } else if (_numOwners == 3){

            require(bytes(ownerAgreements[0].functionCode).length > 0 && bytes(ownerAgreements[1].functionCode).length > 0
            && bytes(ownerAgreements[2].functionCode).length > 0, "Agreement not set");

            require(ownerAgreements[0].yesno == ownerAgreements[1].yesno && 
            ownerAgreements[0].yesno == ownerAgreements[2].yesno, "Opinions Do Not Match");
            
            require(keccak256(bytes(ownerAgreements[0].functionCode)) == keccak256(bytes(ownerAgreements[1].functionCode)) && 
            keccak256(bytes(ownerAgreements[0].functionCode)) == keccak256(bytes(ownerAgreements[2].functionCode)), "Functions Do Not Match");
            
            require(ownerAgreements[0].parameters.length == ownerAgreements[1].parameters.length
            && ownerAgreements[0].parameters.length == ownerAgreements[2].parameters.length, "Parameter size do not match");

            for (uint i=0; i<ownerAgreements[0].parameters.length; i++){
                require(ownerAgreements[0].parameters[i] == ownerAgreements[1].parameters[i], "Function Parameters Do Not Match");
                require(ownerAgreements[0].parameters[i] == ownerAgreements[2].parameters[i], "Function Parameters Do Not Match");
            }

            //require(keccak256(bytes(ownerAgreements[0].decision)) == keccak256(bytes(ownerAgreements[1].decision)) && 
            //keccak256(bytes(ownerAgreements[0].decision)) == keccak256(bytes(ownerAgreements[2].decision)), "Decision Parameters Do Not Match");
        }
        _;
    }

    constructor() {
            _owners[0] = msg.sender;
            _genesisOwner = msg.sender;
            _numOwners = 1;
            //ownerAgreements[0] = AgreementData(false, "contract initialization", "");
    }

       function owners() public view virtual returns (address[3] memory) {
           return _owners;
       }

       function addGenesisOwners(address newOwner) isGenesisOwner public returns (bool){
           for (uint i = 0; i < _owners.length; i++){
               if (_owners[i] == address(0x0)){
                   _owners[i] = newOwner;
                   _numOwners += 1;
                   return true;
               }
           }
           return false;
       }

       function getOwnerIndex(address Owner) onlyOwner private view returns (uint index){
           for (uint i=0; i<3; i++){
               if (_owners[i] == Owner){
                   return i;
               }
           }
       }

        function getAgreements() public view returns (AgreementData[3] memory){
           return ownerAgreements;
       }

       function addAgreement(bool yesno, string memory functionCode, uint[] memory decision, string memory comment)
       onlyOwner public {
           uint index = getOwnerIndex(msg.sender);
           ownerAgreements[index] = AgreementData(yesno, functionCode, decision, comment);
       }
 

}

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address spender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Transfer(address indexed spender, address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 oldAmount, uint256 amount);
}

contract SimpleToken is ERC20Interface, OwnerHelper {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    uint256 public _totalSupply;
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    
    constructor(string memory getName, string memory getSymbol) {
        _name = getName;
        _symbol = getSymbol;
        _decimals = 18;
        _totalSupply = 100000000e18;
        _balances[msg.sender] = _totalSupply;
    }

    function testOne() onlyOwner public view returns (string memory){
        return "hi";
    }

    function testTwo() onlyOwner agreementOnly public view returns (string memory){
        string memory testTwoCode = "B4";
        require(keccak256(bytes(ownerAgreements[0].functionCode)) == keccak256(bytes(testTwoCode)), "Consensus reached, but wrong function call");
        return "Test Two: multi-sig consensus success";
    }

    function testThree(uint param1, uint param2) onlyOwner agreementOnly public view returns (uint){
        //uint param1, string memory param2
        string memory testTwoCode = "F7";
        require(keccak256(bytes(ownerAgreements[0].functionCode)) == keccak256(bytes(testTwoCode)), "Consensus reached, but wrong function call");
        require(param1 == ownerAgreements[0].parameters[0] && param2 == ownerAgreements[0].parameters[1], "Consensus reached with correct function, but wrong parameter inputs");
        return param1 + param2;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint amount) external virtual override returns (bool) {
        uint256 currentAllownace = _allowances[msg.sender][spender];
        require(currentAllownace >= amount, "ERC20: Transfer amount exceeds allowance");
        _approve(msg.sender, spender, currentAllownace, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        emit Transfer(msg.sender, sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance, currentAllowance - amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
    }
    
    function _approve(address owner, address spender, uint256 currentAmount, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(currentAmount == _allowances[owner][spender], "ERC20: invalid currentAmount");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, currentAmount, amount);
    }
}