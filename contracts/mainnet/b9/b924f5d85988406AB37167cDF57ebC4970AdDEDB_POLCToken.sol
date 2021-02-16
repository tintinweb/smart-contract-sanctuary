/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        
}

interface ItokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external returns (bool); 
}

interface IERC20Token {
    function totalSupply() external view returns (uint256 supply);
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract Ownable {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }


    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

contract StandardToken is IERC20Token {
    
    using SafeMath for uint256;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public _totalSupply;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function totalSupply() override public view returns (uint256 supply) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) override virtual public returns (bool success) {
        require(_to != address(0x0), "Use burn function instead");                              
		require(_value >= 0, "Invalid amount"); 
		require(balances[msg.sender] >= _value, "Not enough balance");
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) override virtual public returns (bool success) {
        require(_to != address(0x0), "Use burn function instead");                               
		require(_value >= 0, "Invalid amount"); 
		require(balances[_from] >= _value, "Not enough balance");
		require(allowed[_from][msg.sender] >= _value, "You need to increase allowance");
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) override public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) override public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) override public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
}

contract POLCToken is Ownable, StandardToken {

    using SafeMath for uint256;
    string public name = "Polka City";
    uint8 public decimals = 18;
    string public symbol = "POLC";
    mapping (address => bool) public lockedWallets;

    struct TimeLock {
        uint firstRelease;
        uint totalAmount;
        uint lockedBalance;
    }
    
    mapping (address => TimeLock) public timeLocks; 
    
    address public platformWallet;
    bool public limitContracts;
    mapping (address => bool) public contractsWhiteList;
    mapping (address => uint) public lastTXBlock;
    uint public walletUnlockDate;
    event Burn(address indexed from, uint256 value);


// token sale
    address payable public salesWallet;

    uint256 public soldOnPSale;
    uint256 public soldOnCSale;
    address private marketingWallet;
    uint256 public PRIVATESALE_START = block.timestamp;
    uint256 public constant PRIVATESALE_END = 1613951999;
    uint256 public constant CROWDSALE_START = 1614448800;
    uint256 public constant CROWDSALE_END = 1615766399;
    uint256 public constant PSALE_WEI_FACTOR = 20000;
    uint256 public constant CSALE_WEI_FACTOR = 15000;
    uint256 public constant PSALE_HARDCAP = 2500000 ether;
    uint256 public constant CSALE_HARDCAP = 7500000 ether;
    event TokensSold(address indexed to, uint256 amount);
    
    constructor() {
        platformWallet = 0x2524e7e53E655cA94986f6f445a74A4796A42289;
        _totalSupply = 250000000 ether;
        walletUnlockDate = CROWDSALE_END;

        // Marketing wallet - 5000000 tokens, (4500000 Locked - progressive release)
        marketingWallet = 0x09911dD354141452a21eB69527B510a8941CaaFF;
        balances[marketingWallet] = 5000000 ether;
        timeLocks[marketingWallet] = TimeLock((PRIVATESALE_END - 30 days), 4000000 ether, 4000000 ether);
        emit Transfer(address(0x0), marketingWallet, balances[marketingWallet]);
        
        // Team wallet - 10000000 tokens (Locked - progressive release)
        address team = 0x3A23D3e9BE80A804fceB418b451E3100d9264F7E;
        balances[team] = 10000000 ether;
        timeLocks[team] = TimeLock((PRIVATESALE_START + 180 days), 10000000 ether, 10000000 ether);
        
        emit Transfer(address(0x0), team, balances[team]);
        
        // Uniswap and exchanges - 26000000 tokens locked until crowdsale ends
        address exchanges = 0x6B65ddFe7f46594181A05a121Ee93FcF71e586bC;  
        balances[exchanges] = 25000000 ether;
        emit Transfer(address(0x0), exchanges, balances[exchanges]);
        lockedWallets[exchanges]  = true;
        

        // Platform tokens
        balances[platformWallet] = 200000000 ether;
        emit Transfer(address(0x0), platformWallet, (200000000 ether));
        
        // Sales wallet, private and crowdsale balances
        salesWallet = payable(0x8F8A97B50A325499Eb7DD72956cCd307E2B8d6a4);
        balances[salesWallet] = 10000000 ether;
        emit Transfer(address(0x0), salesWallet, balances[salesWallet]);

    }
    
    function transfer(address _to, uint256 _value) override public returns (bool success) {
        require(canTransfer(msg.sender));
        require(_value <= (balances[msg.sender] - timeLocks[msg.sender].lockedBalance));
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        require(canTransfer(_from));
        require(_value <= (balances[_from] - timeLocks[msg.sender].lockedBalance));
        return super.transferFrom(_from, _to, _value);
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Not enough balance");
		require(_value >= 0, "Invalid amount"); 
        balances[msg.sender] = balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        ItokenRecipient recipient = ItokenRecipient(_spender);
        require(recipient.receiveApproval(msg.sender, _value, address(this), _extraData));
        return true;
    }
    

    function releaseTokens(address _account) public {
        uint steps = (block.timestamp - timeLocks[_account].firstRelease) / (30 days);
        if (steps >=20) {
            timeLocks[_account].lockedBalance = 0;
        } else {
            timeLocks[_account].lockedBalance = timeLocks[_account].totalAmount - ((timeLocks[_account].totalAmount/20) * steps);
        }
    }
    
    function canTransfer(address _wallet) private returns (bool) {
        require(checkTransferLimit() == true);
        if (lockedWallets[_wallet] == true) {
            if (block.timestamp > walletUnlockDate) {
                lockedWallets[_wallet] = false;
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    
    function checkTransferLimit() internal returns (bool txAllowed) {
        address _caller = msg.sender;
        if (isContract(_caller)) {
            if (limitContracts == true && contractsWhiteList[_caller] == false) {
                if (lastTXBlock[_caller] == block.number) {
                    return false;
                } else {
                    lastTXBlock[_caller] = block.number;
                    return true;
                }
            } else {
                return true;
            }
        } else {
            return true;
        }
    }
    
    function setLimitContracts(bool _limit) public onlyOwner {
        limitContracts = _limit;
    }
    
    function includeWhiteList(address _contractAddress) public onlyOwner {
        contractsWhiteList[_contractAddress] = true;
    }
    
    function removeWhiteList(address _contractAddress) public onlyOwner {
        contractsWhiteList[_contractAddress] = false;
    }
    
    function isWalletLocked(address _wallet) public view returns (bool isLocked) {
        return lockedWallets[_wallet];
    }
    
    function setPlatformWallet(address _platformWallet) public onlyOwner {
        platformWallet = payable(_platformWallet);
    }

    function getLockedBalance(address _wallet) public view returns (uint256 lockedBalance) {
        return timeLocks[_wallet].lockedBalance;
    }
    
    // token sale

    function buy() public payable {
        require(((block.timestamp > PRIVATESALE_START) && (block.timestamp < PRIVATESALE_END)) || ((block.timestamp > CROWDSALE_START) && (block.timestamp < CROWDSALE_END)), "Contract is not selling tokens");
        uint weiValue = msg.value;
        require(weiValue >= (5 * (10 ** 16)));
        bool lockAccount = false;
        uint amount = 0;
        if ((block.timestamp > PRIVATESALE_START) && (block.timestamp < PRIVATESALE_END)) {
            amount = PSALE_WEI_FACTOR * weiValue;
            soldOnPSale += amount;
            require((soldOnPSale) <= (PSALE_HARDCAP), "That quantity is not available");
        } else {
            amount = CSALE_WEI_FACTOR * weiValue;
            soldOnCSale += amount;
            require((soldOnCSale) <= (CSALE_HARDCAP), "That quantity is not available");
            lockAccount = true;
        }

        balances[salesWallet] = balances[salesWallet].sub(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        if ( lockAccount == true) lockedWallets[msg.sender] = true;
        require(salesWallet.send(weiValue));
        emit Transfer(salesWallet, msg.sender, amount);
        if (CSALE_HARDCAP == soldOnCSale && block.timestamp < 1615140000) {  // If hardcap is reached before 2021/03/07 18:00, change unlock dates
            timeLocks[marketingWallet].firstRelease = block.timestamp - 30 days;
        }

    }
    
    function burnUnsold() public onlyOwner {
        require(block.timestamp > CROWDSALE_END);
        uint currentBalance = balances[salesWallet];
        balances[salesWallet] = 0;
        _totalSupply = _totalSupply.sub(currentBalance);
        emit Burn(salesWallet, currentBalance);
    }
}