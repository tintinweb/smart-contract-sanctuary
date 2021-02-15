/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

pragma solidity 0.4.23;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract tokensender {
    mapping(address => uint256) public txCount;
    address public owner;
    address public pendingOwner;
    uint16 public arrayLimit = 150;
    uint256 public discountStep = 0.00005 ether;
    uint256 public fee = 0.05 ether;
    
    //VIP Variables
    mapping(address => bool) public addressToIsVIP;
    uint256 public VIPPrice;
    address[] public VIPS;
    
    event VIPAddresses(address VIPAddress);
    
    //Referall Variables
    uint256 public referallPercentage;
    address[] public referallAddresses;
    mapping(address => uint256) public referallAddressToIncome;
    
    event Multisended(uint256 total, address tokenAddress);
    event ClaimedTokens(address token, address owner, uint256 balance);

    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }
    
    modifier hasFee() {
        if(!addressToIsVIP[msg.sender]) {
            require(msg.value >=  fee - getDiscountRate(msg.sender));   
        }
        _;
    }

    constructor(address _owner, address _pendingOwner) public {
        owner = _owner;
        pendingOwner = _pendingOwner;
    }

    function() public payable {}
    
    function buyVIP(address referrer) external payable hasFee {
        require(msg.value  == VIPPrice + fee);
        require(addressToIsVIP[msg.sender] == false, "Address is already VIP!");

        addressToIsVIP[msg.sender] = true;
        VIPS.push(msg.sender);
        
        if(referallAddressToIncome[referrer] == 0) {
            referallAddresses.push(referrer);
        }
        
        if(referrer != 0x0000000000000000000000000000000000000000) {
            referrer.transfer(fee * referallPercentage / 100);
            owner.transfer(fee * (100 - referallPercentage) / 100);
            
            referallAddressToIncome[referrer] += fee * referallPercentage / 100;
        } else {
            owner.transfer(fee);
        }
        
        emit VIPAddresses(msg.sender);
    }
    
    function getDiscountRate(address _customer) public view returns(uint256) {
        uint256 count = txCount[_customer];
        return count * discountStep;
    }
    
    function getCurrentFee(address _customer) public view returns(uint256) {
        return fee - getDiscountRate(_customer);
    }
    
    function claimOwner(address _newPendingOwner) public {
        require(msg.sender == pendingOwner);
        owner = pendingOwner;
        pendingOwner = _newPendingOwner;
    }
    
    function changeTreshold(uint16 _newLimit) public onlyOwner {
        arrayLimit = _newLimit;
    }
    
    function changeFee(uint256 _newFee) public onlyOwner {
        fee = _newFee;
    }
    
    function changeDiscountStep(uint256 _newStep) public onlyOwner {
        discountStep = _newStep;
    } 
    
    function multisendToken(address token, address[] _contributors, uint256[] _balances, address referrer) public hasFee payable {
        uint256 total = 0;
        require(_contributors.length <= arrayLimit);
        ERC20 erc20token = ERC20(token);
        uint8 i = 0;
        require(erc20token.allowance(msg.sender, this) > 0);
        for (i; i < _contributors.length; i++) {
            erc20token.transferFrom(msg.sender, _contributors[i], _balances[i]);
            total += _balances[i];
        }
        txCount[msg.sender]++;
        Multisended(total, token);
        
        if(addressToIsVIP[msg.sender] == false) {
            if(referrer != 0x0000000000000000000000000000000000000000) {
                referrer.transfer(fee * referallPercentage / 100);
                owner.transfer(fee * (100 - referallPercentage) / 100);
                
                if(referallAddressToIncome[referrer] == 0) {
                    referallAddresses.push(referrer);
                }
                
                referallAddressToIncome[referrer] += fee * referallPercentage / 100;
            } else {
                owner.transfer(fee);
            }
        }
    }
    
    function multisendEther(address[] _contributors, uint256[] _balances, address referrer) public hasFee payable {
        require(_contributors.length <= arrayLimit);
        
        uint256 totalBalances;
        
        for(uint256 j=0;j<_balances.length;j++) {
            totalBalances += _balances[j];
        }
        
        if(addressToIsVIP[msg.sender]) {
            require(msg.value == totalBalances);
        } else {
            require(msg.value == fee + totalBalances);
            
            if(referrer != 0x0000000000000000000000000000000000000000) {
                referrer.transfer(fee * referallPercentage / 100);
                owner.transfer(fee * (100 - referallPercentage) / 100);
                
                if(referallAddressToIncome[referrer] == 0) {
                    referallAddresses.push(referrer);
                }
                
                referallAddressToIncome[referrer] += fee * referallPercentage / 100;
            } else {
                owner.transfer(fee);
            }
        }
        
        uint256 total = 0;
        
        uint8 i = 0;
        for (i; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);
            total += _balances[i];
        }
        txCount[msg.sender]++;
        
        Multisended(total, address(0));
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(this);
        erc20token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }
    
    function addVIP(address _account) external onlyOwner {
        require(addressToIsVIP[_account] == false, "Address is already VIP!");
        
        addressToIsVIP[_account] = true;
        VIPS.push(_account);
        
        emit VIPAddresses(_account);
    }
    
    function removeVIP(address _account) external onlyOwner {
        require(addressToIsVIP[_account] == true, "Address is not a VIP!");
        
        addressToIsVIP[_account] = false;
        for(uint256 i=0;i<VIPS.length;i++) {
            if(VIPS[i] == _account) {
                delete VIPS[i];
                break;
            }
        }
    }
    
    function setVIPPrice(uint256 _newPrice) external onlyOwner {
        VIPPrice = _newPrice;
    }
    
    function setReferallPercentage(uint256 _newReferallPercentage) external onlyOwner {
        referallPercentage = _newReferallPercentage;
    }
}