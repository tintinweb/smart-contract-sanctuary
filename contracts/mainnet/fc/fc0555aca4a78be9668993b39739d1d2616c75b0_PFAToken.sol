pragma solidity ^0.4.20;

interface ERC20Token {

    function totalSupply() constant external returns (uint256 supply);

    function balanceOf(address _owner) constant external returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is ERC20Token{
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

    function balanceOf(address _owner) constant external returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        if(msg.data.length < (2 * 32) + 4) { revert(); }

        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        if(msg.data.length < (3 * 32) + 4) { revert(); }

        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant external returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function totalSupply() constant external returns (uint256 supply){
        return totalSupply;
    }
}

contract PFAToken is Token{
    address owner = msg.sender;

    address admin;

    bool private paused;
    bool private mintStage;
    bool private icoStage;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;
    uint256 public minimumContribution;
    address public fundsWallet;
    uint256 public tokenFunded;
    uint256 public coinMinted;

    //Events
    event Mint(address indexed _to, uint256 _value);
    event RateChanged(uint256 _rate);
    event ContributionChanged(uint256 _min);
    event AdminChanged(address _address);

    //modifier
    modifier onlyOwner{
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    modifier whenNotPause{
        require(!paused);
        _;
    }

    modifier isMintStage{
        require(mintStage);
        _;
    }

    modifier isICOStage{
        require(icoStage);
        _;
    }

    //consturtor
    function PFAToken() {
        paused = false;
        mintStage = true;
        icoStage = false;

        balances[msg.sender] = 1000000000 * 1000000000000000000;
        totalSupply = 1000000000 * 1000000000000000000;
        name = "Price Fitch Asset";
        decimals = 18;
        symbol = "PFA";
        unitsOneEthCanBuy = 100;
        minimumContribution = 10 finney;
        fundsWallet = msg.sender;
        tokenFunded = 0;
        coinMinted = 0;
    }

    // Mint
    function mint(address _to, uint256 _value) external onlyOwner isMintStage{
      balances[_to] = balances[_to] + _value;
      coinMinted = coinMinted + _value;
      Mint(_to, _value);
    }

    function send(address _to, uint256 _value) external onlyOwner{
      balances[fundsWallet] = balances[fundsWallet] - _value;
      balances[_to] = balances[_to] + _value;
      Transfer(fundsWallet, _to, _value);
    }

    // fallback function for ICO use.
    function() payable whenNotPause isICOStage{
        if (msg.value >= minimumContribution){
            totalEthInWei = totalEthInWei + msg.value;
            uint256 amount = msg.value * unitsOneEthCanBuy;
            if (balances[fundsWallet] < amount) {
                return;
            }

            tokenFunded = tokenFunded + amount;

            balances[fundsWallet] = balances[fundsWallet] - amount;
            balances[msg.sender] = balances[msg.sender] + amount;

            Transfer(fundsWallet, msg.sender, amount);
        }

        fundsWallet.transfer(msg.value);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {
            revert();
        }

        return true;
    }

    //Set Admin address
    function setAdmin(address _address) external onlyOwner{
      admin = _address;
      AdminChanged(_address);
    }

    //Change Token rate
    function changeTokenRate(uint256 _rate) external onlyOwner{
      unitsOneEthCanBuy = _rate;
      RateChanged(_rate);
    }

    function changeMinimumContribution(uint256 _min) external onlyOwner{
      minimumContribution = _min;
      ContributionChanged(_min);
    }

    //stage lock function
    function mintStart(bool) external onlyOwner{
        mintStage = true;
    }

    function mintEnd(bool) external onlyOwner{
        mintStage = false;
    }

    function icoStart(bool) external onlyOwner{
        icoStage = true;
    }

    function icoEnd(bool) external onlyOwner{
        icoStage = false;
    }

    function pauseContract(bool) external onlyOwner{
        paused = true;
    }

    function unpauseContract(bool) external onlyOwner{
        paused = false;
    }

    //return stats of token
    function getStats() external constant returns (uint256, uint256, bool, bool, bool) {
        return (totalEthInWei, tokenFunded, paused, mintStage, icoStage);
    }

}