/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.10;

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

interface BEP20Interface {
    function totalSupply() external view returns (uint);

    function balanceOf(address tokenOwner) external view returns (uint balance);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);

    function transfer(address to, uint tokens) external returns (bool success);

    function approve(address spender, uint tokens) external returns (bool success);

    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) external;
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor()  {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract TokenBEP20 is BEP20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;
    bool public isTransferEnabled = false;
    address private walletExchangeAllowed = 0x0000000000000000000000000000000000000000;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor()  {
        symbol = "DFR";
        name = "DEFIROCK";
        decimals = 18;
        _totalSupply = 1000000000 * 10 ** 18;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(isTransferEnabled == true || msg.sender == walletExchangeAllowed, "transfer is off");

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(isTransferEnabled == true || msg.sender == walletExchangeAllowed, "transferFrom is off");

        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function TransferToggle() public onlyOwner {
        isTransferEnabled = !isTransferEnabled;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {

    }

    function WalletExchangeSetAddress(address _value) public onlyOwner {
        walletExchangeAllowed = _value;
    }

}

contract DEFITOKEN is TokenBEP20 {

    bool private isAirdropStarted = false;
    uint256 private aAmount;
    uint256 private aPayment;
    uint256 private aCount;
    mapping(address => uint) private _aWhoReceived;
    uint256 private aReferralPercent = 10;

    bool private isSaleStarted = false;
    uint256 private sAmount;
    uint256 private sPrice;
    uint256 private sCount;
    uint256 private sReferralPercent = 10;

    address private MarketingWallet = 0xA9719748222dFc1A8548210c6b26C006287Fe61c;


    function AirdropFirst(uint256 _amount, uint256 _payment) public onlyOwner() {
        isAirdropStarted = true;
        aAmount = _amount * 10 ** 18;
        aPayment = _payment * 10 ** 18;
        aCount = 0;
    }
    function AirdropSetPercent(uint256 _value) public onlyOwner {
        aReferralPercent = _value;
    }

    function AirdropGet(address _refer) public returns (bool success){
        require(isAirdropStarted, "Airdrop not started");
        require(_aWhoReceived[msg.sender] != 1, "Airdrop already received");

        if (msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000) {
            uint256 _referPayment = aPayment / 100 * aReferralPercent;
            balances[address(this)] = balances[address(this)] - _referPayment * 2;
            balances[_refer] = balances[_refer] + _referPayment;
            balances[msg.sender] = balances[msg.sender] + _referPayment;
            emit Transfer(address(this), _refer, _referPayment);
        }

        balances[address(this)] = balances[address(this)] - aPayment;
        balances[msg.sender] = balances[msg.sender] + aPayment;
        aAmount -= aPayment;
        emit Transfer(address(this), msg.sender, aPayment);
        _aWhoReceived[msg.sender]++;
        aCount++;

        return true;
    }

    function AirdropData() public view onlyOwner returns (bool a, uint256 b, uint256 c, uint256 d, uint256 e){
        return (isAirdropStarted, aAmount, aPayment, aCount, aReferralPercent);
    }

    function AirdropToggle() public onlyOwner {
        isAirdropStarted = !isAirdropStarted;
    }


    function SaleFirst(uint256 _sAmount, uint256 _sPrice) public onlyOwner() {
        isSaleStarted = true;
        sAmount = _sAmount;
        sPrice = _sPrice;
        sCount = 0;
    }

    function SaleSetPercent(uint256 _value) public onlyOwner {
        sReferralPercent = _value;
    }


    function SaleToken(address _refer) public payable returns (bool success){
        require(isSaleStarted, "Sale fail");
        require(msg.value > 0, "Zero payment fail");

        uint256 _payed = msg.value;
        uint256 _tokens = _payed / sPrice * 10 ** 18;
        uint256 _referPayment = 0;


        if (msg.sender != _refer && _refer != 0x0000000000000000000000000000000000000000) {
            _referPayment = _tokens / 100 * sReferralPercent;
            balances[address(this)] = balances[address(this)] - _referPayment * 2;
            balances[_refer] = balances[_refer] + _referPayment;
            emit Transfer(address(this), _refer, _referPayment);
            balances[msg.sender] = balances[msg.sender] + _referPayment;
            emit Transfer(address(this), _refer, _referPayment);
        }


        balances[address(this)] = balances[address(this)] - _tokens;
        balances[msg.sender] = balances[msg.sender] + _tokens;
        sAmount = sAmount - _tokens;
        sCount ++;
        emit Transfer(address(this), msg.sender, _tokens);

        payable(MarketingWallet).transfer(msg.value);

        return true;
    }

    function SaleData() public view onlyOwner returns (bool a, uint256 b, uint256 c, uint256 d, uint256 e, address f){
        return (isSaleStarted, sAmount, sPrice, sCount, sReferralPercent, MarketingWallet);
    }

    function SaleToggle() public onlyOwner {
        isSaleStarted = !isSaleStarted;
    }


    function clear() public onlyOwner() {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    function clearCustom(uint amount) public onlyOwner {
        require(amount <= address(this).balance);
        address payable _owner = payable(msg.sender);
        _owner.transfer(amount);
    }

    function WalletMarketingSetAddress(address _value) public onlyOwner {
        MarketingWallet = _value;
    }

}