pragma solidity 0.7.1;

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

abstract contract ERC20Basic {
    function totalSupply() external virtual returns (uint);
    function balanceOf(address who) public virtual view returns (uint);
    function transfer(address to, uint value) public virtual;
    event Transfer(address indexed from, address indexed to, uint value);
}

abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view virtual returns (uint);
    function transferFrom(address from, address to, uint value) public virtual;
    function approve(address spender, uint value) public virtual;
    event Approval(address indexed owner, address indexed spender, uint value);
}

abstract contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    function balanceOf(address _owner) public override virtual view returns (uint balance) {
        return balances[_owner];
    }
}

abstract contract StandardToken is BasicToken, ERC20 {
    using SafeMath for uint;
    
    enum ETransferType{
        transferTo,
        transferFrom,
        transferToTeam
    }
    
    mapping (address => mapping (address => uint)) allowed;
    
    address internal devAddress = 0xBBa154c29688A7422348f68474443b5665d6d92F;
    address internal marketingAddress = 0xFDb4a96229104d7A2F82D520EfD4CffCF6BBe663;
    address internal adviserAddress = 0x544A4d166a1335F50a836F17F01f18Bf2011a440;
    
    address internal privateSaleAddress = 0xaE1F789fAEAAe491327BC84EA5435EdE0d895F67;
    address internal publicSaleAddress = 0x6700e2CF974Bd32014f4C6F1fa35E0DcFDdE7f91;
    address internal communityAddress = 0xBc6F3E510Ca895828c777d1631891D2a8957F36D;
    
    //Specify time that team addresses can transfer token
    uint256 internal teamAddressCanTransferTimestamp = 1609459200;  //01-01-2021
    
    function transfer(address _to, uint _value) public override virtual onlyPayloadSize(2 * 32) {
        _transfer(msg.sender,_to,_value, ETransferType.transferTo);
    }

    function transferFrom(address sender, address recipient, uint amount) public virtual override onlyPayloadSize(3 * 32) {
        validateNotTransferToTeamAddress(recipient);
        validateTeamCanOnlyTransferAfterConfiguredTime(sender);
        
         require(balances[sender] >= amount && amount > 0, "Not enough balance");
         require(allowance(sender, _msgSender()) >= amount,"Allowance is not enough");
         
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount, ETransferType transferType) internal {
        require(balances[sender] >= amount);
        
        if(transferType != ETransferType.transferToTeam){
            validateNotTransferToTeamAddress(recipient);
            validateTeamCanOnlyTransferAfterConfiguredTime(sender);
        }
        
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function approve(address _spender, uint _value) public virtual override onlyPayloadSize(2 * 32) {
        require(_value >= 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public virtual view override returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    
    function _msgSender() internal view returns(address){
        return msg.sender;
    }
    
    function validateNotTransferToTeamAddress(address recipient) internal view{
        require(recipient!= devAddress,"Can not transfer to dev address");
        require(recipient!= marketingAddress,"Can not transfer to marketing address");
        require(recipient!= adviserAddress,"Can not transfer to adviser address");
        require(recipient!= privateSaleAddress,"Can not transfer to private sale address");
        require(recipient!= publicSaleAddress,"Can not transfer to public sale address");
        require(recipient!= communityAddress,"Can not transfer to community address");
    }
    
    function validateTeamCanOnlyTransferAfterConfiguredTime(address sender) internal view{
        if(sender == devAddress || sender == marketingAddress || sender == adviserAddress){
            require (_now() >= teamAddressCanTransferTimestamp,"The team addresses is allowed to transfer after 01-01-2021");
        }
    }
    
    function _now() internal view returns(uint256){
        return block.timestamp;
    }
}

contract PFIToken is StandardToken {
    modifier onlyOwner{
        require(_msgSender() == owner, "Fobidden");
        _;
    }
    
    
    using SafeMath for uint;
    
    string public name = 'PFIToken';
    string public symbol = 'PFI';
    uint public decimals = 18;
    uint256 public override totalSupply = 21500000000000000000000;
    address public owner;

    constructor () {
        balances[_msgSender()] = totalSupply;
        owner = _msgSender();
        
        _transferToTeam(devAddress, totalSupply.mul(87).div(1000)); //8.7%
        _transferToTeam(marketingAddress, totalSupply.mul(8).div(100)); //8%
        _transferToTeam(adviserAddress, totalSupply.mul(5).div(100)); //5%
        _transferToTeam(privateSaleAddress, totalSupply.div(10)); //10%
        _transferToTeam(publicSaleAddress, totalSupply.mul(3).div(10)); //30%
        _transferToTeam(communityAddress, totalSupply.mul(383).div(1000)); //38.3%
    }
    
    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function burn(address account, uint256 amount) public onlyOwner  {
        require(account != address(0), "ERC20: burn from the zero address");

        balances[account] = balances[account].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _transferToTeam(address recipient, uint256 amount) internal {
        _transfer(_msgSender(),recipient,amount, ETransferType.transferToTeam);
    }

    event Issue(uint amount);
}

// SPDX-License-Identifier: MIT