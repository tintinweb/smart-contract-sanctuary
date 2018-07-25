pragma solidity ^0.4.17;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// Owned contract
contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    //Transfer owner rights, can use only owner (the best practice of secure for the contracts)
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //Accept tranfer owner rights
    function acceptOwnership() public onlyOwner {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract VTest is ERC20Interface, Owned {
    using SafeMath for uint;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint private _totalSupply;
    address private fundsWallet;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function VTest() public {
        symbol = &#39;VTest&#39;;
        name = &#39;VTest Token&#39;;
        decimals = 18;
        _totalSupply = 1000000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
        fundsWallet = msg.sender;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    //Send tokens to users from the exel file
    function send(address[] receivers, uint[] values) public payable {
      for (uint i = 0; receivers.length > i; i++) {
           sendTokens(receivers[i], values[i]);
        }
    }

    //Send tokens to specific user
    function sendTokens (address receiver, uint token) public onlyOwner {
        require(balances[msg.sender] >= token);
        balances[msg.sender] -= token;
        balances[receiver] += token;
        Transfer(msg.sender, receiver, token);
    }

    //Send initial tokens
    function sendInitialTokens (address user) public onlyOwner {
        sendTokens(user, balanceOf(owner));
    }

}

contract VTestDistribution{
    using SafeMath for uint;
    VTest public token;
    address public owner;
    //check this counter to know how many recipients got the Airdrop
    uint256 public counter;
    mapping(address => mapping(uint => uint)) CustodyAccount;
    mapping (address => bool) admins;

    uint public icoEndTime;
    uint public unlockDate1;
    uint public unlockDate2;
    uint public unlockDate3;
    uint public Day = 12*60*60;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    event TokenTransferToCustody(address userAddress, uint period, uint value);
    event TokenClaimed(address userAddress, uint claimedValu, uint claimedDate);


    function VTestDistribution(address _token, uint _icoEndTime, uint _waitPeriod) public{
        require(_token != address(0));
        token = VTest(_token);
        owner = msg.sender;
        icoEndTime = _icoEndTime;
        _waitPeriod;
        unlockDate1 = icoEndTime + _waitPeriod*Day;//300;
        unlockDate2 = unlockDate1 + 1*Day;//3*30*Day;//5*60;
        unlockDate3 = unlockDate2 + 2*Day;//3*30*Day;//5*60;
    }

    function setAdmin(address _admin, bool isAdmin) public onlyOwner {
        admins[_admin] = isAdmin;
    }

    //Air drop transfer
    function airdropToken(address[] recipients, uint value) public onlyAdmin {
        require(recipients.length>0);

        counter = 0;

        for(uint i=0; i < recipients.length; i++){
            tokenTransfer(recipients[i], 1, value);
            counter++;
        }
    }

    //Normal transfer to custody account
    function batchTransfer(address[] recipients, uint period, uint[] value) public onlyAdmin {
        require(recipients.length>0);

        for(uint i=0; i < recipients.length; i++){
            tokenTransfer(recipients[i], period, value[i]);
        }
    }

    function tokenTransfer(address recipient, uint period, uint value) public onlyAdmin {

        CustodyAccount[recipient][period] = CustodyAccount[recipient][period].add(value);

        TokenTransferToCustody(recipient, period, value);
    }

    //Make transfer for VIP 
    function batchTransferVIP(address[] recipients, uint[] value) public onlyAdmin {
        require(recipients.length>0);

        for(uint i=0; i < recipients.length; i++){
            tokenTransferVIP(recipients[i], value[i]);   
        }
    }

    function tokenTransferVIP(address recipient, uint value) public onlyAdmin {
        uint amount1 = value.div(3);
        uint amount2 = amount1;
        uint amount3 = value.sub(amount1).sub(amount2);

        tokenTransfer(recipient, 1, amount1);
        tokenTransfer(recipient, 2, amount2);
        tokenTransfer(recipient, 3, amount3);   

        //3 means this is vip transfer
        TokenTransferToCustody(recipient, 3, value);
    }

    function getBalance(address userWallet, uint period) public constant returns(uint balance){
        return CustodyAccount[userWallet][period];
    }
  
    //Claim token to user account
    function claimToken(uint period) public returns (bool success) {
        if(period == 1) {
            require(now > unlockDate1);
        } else if(period == 2) {
            require(now > unlockDate2);
        } else if(period == 3) {
            require(now > unlockDate3);
        } else {
            return false;
        }

        require(CustodyAccount[msg.sender][period] > 0);

        token.transfer(msg.sender, CustodyAccount[msg.sender][period]);
        CustodyAccount[msg.sender][period] = 0;

        TokenClaimed(msg.sender, CustodyAccount[msg.sender][period], now);
        return true;
    }

}