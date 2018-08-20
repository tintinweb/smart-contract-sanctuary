pragma solidity ^0.4.20;

contract Token {
    function totalSupply() public constant returns (uint256 supply) {}
    function balanceOf(address _owner) public constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) public returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
    function approve(address _spender, uint256 _value) public returns (bool success) {}
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract Obredis is StandardToken { 
    string public name;                   // Token Name
    uint8 public decimals;                // How many decimals the token has
    string public symbol;                 // Token identifier
    address public fundsWallet;           // Wallet which manages the contract
    uint256 public totalRewards;
    uint256 public newReward;
    address[] public addresses;
    mapping (address => bool) public isAddress;
    bool public allRewPaid;
    mapping (address => bool) public awaitingRew;
    
    
    event Minted(uint256 qty,uint256 totalSupply);
    event Burned(uint256 qty,uint256 totalSupply);
    event Reward(uint256 qty);
    
    function Obredis() public {
        balances[msg.sender] = 0;
        totalSupply = 0;
        name = "Obelisk Reward Token";
        decimals = 18;
        symbol = "ORT";
        allRewPaid = true;
        awaitingRew[msg.sender] = false;
        fundsWallet = msg.sender;
        addresses.push(msg.sender);
        isAddress[msg.sender] = true;
    }

    function() public {
    }

    function transfer(address _to, uint256 _value) public canSend returns (bool success) {
        // Transfer Tokens
        require(super.transfer(_to,_value));
        if (!isAddress[_to]){
            addresses.push(_to);
            isAddress[_to] = true;
        }
        // Return success flag
        return true;
    }

    modifier isOwner {
        require(msg.sender == fundsWallet);
        _;
    }
    
    modifier canSend {
        require(allRewPaid);
        _;
    }
    
    function forceTransfer(address _who, uint256 _qty) public isOwner returns (bool success) {
        // owner can transfer qty from a wallet (in case your hopeless mates lose their private keys).
        if (balances[_who] >= _qty && _qty > 0) {
            balances[_who] -= _qty;
            balances[fundsWallet] += _qty;
            Transfer(_who, fundsWallet, _qty);
            return true;
        } else { 
            return false;
        }
    }

    function payReward() public payable isOwner canSend {
        require(msg.value > 0);
        newReward = this.balance; // the only balance will be the scraps after payout
        totalRewards += msg.value;     // only want to update with new amount
        Reward(msg.value);
        allRewPaid = false;
        uint32 len = uint32(addresses.length);
        for (uint32 i = 0; i < len ; i++){
            awaitingRew[addresses[i]] = true;
        }
    }
    
    function payAllRewards() public isOwner {
        require(allRewPaid == false);
        uint32 len = uint32(addresses.length);
        for (uint32 i = 0; i < len ; i++){
            if (balances[addresses[i]] == 0){
                awaitingRew[addresses[i]] = false;
            } else if (awaitingRew[addresses[i]]) {
                addresses[i].transfer((newReward*balances[addresses[i]])/totalSupply);
                awaitingRew[addresses[i]] = false;
            }
        }
        allRewPaid = true;
    }

    function paySomeRewards(uint32 _first, uint32 _last) public isOwner {
        require(_first <= _last);
        require(_last <= addresses.length);
        for (uint32 i = _first; i<= _last; i++) {
            if (balances[addresses[i]] == 0){
                awaitingRew[addresses[i]] = false;
            } else if (awaitingRew[addresses[i]]) {
                addresses[i].transfer((newReward*balances[addresses[i]])/totalSupply);
                awaitingRew[addresses[i]] = false;
            }
        }
        allRewPaid = checkAllRewPaid(); 
    }
    
    function checkAllRewPaid() public view returns(bool success) {
        uint32 len = uint32(addresses.length);
        for (uint32 i = 0; i < len ; i++ ){
            if (awaitingRew[addresses[i]]){
                return false;
            }
        }
        return true;
    }
    
    function updateAllRewPaid() public isOwner {
        allRewPaid = checkAllRewPaid();
    }

    function mint(uint256 _qty) public canSend isOwner {
        require(totalSupply + _qty > totalSupply); // Prevents overflow
        totalSupply += _qty;
        balances[fundsWallet] += _qty;
        Minted(_qty,totalSupply);
        Transfer(0x0, fundsWallet, _qty);
    }
    
    function burn(uint256 _qty) public canSend isOwner {
        require(totalSupply - _qty < totalSupply); // Prevents underflow
        require(balances[fundsWallet] >= _qty);
        totalSupply -= _qty;
        balances[fundsWallet] -= _qty;
        Burned(_qty,totalSupply);
        Transfer(fundsWallet, 0x0, _qty);
    }
    
    function collectOwnRew() public {
        if(awaitingRew[msg.sender]){
            msg.sender.transfer((newReward*balances[msg.sender])/totalSupply);
            awaitingRew[msg.sender] = false;
        }
        allRewPaid = checkAllRewPaid();
    }
    
    function addressesLength() public view returns(uint32 len){
        return uint32(addresses.length);
    }
    
    function kill() public isOwner {
        // Too much money involved to not have a fire exit
        selfdestruct(fundsWallet);
    }
}