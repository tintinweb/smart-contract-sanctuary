pragma solidity ^0.4.24;

/*
    Template by Yunes Crocr&#239;echev
    Token name change by Umberto Ferreira

    http://supremiot.fr - IOT - Blockchain - BigData - Quantic - Cloud

    - 2,000,000 tokens
    - 100% success chances
*/

contract SupremIOTToken {
    string  public constant _name = &quot;Suprem IOT Token&quot;;
    string  public constant _symbol = &quot;SHIOT&quot;;
    uint256 public constant _totalSupply = 2000000 * 10**uint(_decimals);   // WOW, 2,000,000 tokens !
    uint8   public constant _decimals = 18;                                 // OMFG that&#39;s 2,000,000.000000000000000000 tokens now !

    address public owner;                                                   // that&#39;s us
    address public trustedThirdParty;                                       // that&#39;s not us
    uint    public deposited;                                               // the real money
    mapping (address => uint) public balances;                              // the SHIOT balances
    uint256 public availableSupply = 2000000 * 10**uint(_decimals);         // SHIOTs that still hasn&#39;t been sold
    uint    public tokenRate = 100000;                                      // SHIOT rate
    uint[]  public quanticBlockchainBigData;                                // the quantic blockchain big data

    function SupremIOTToken(address _trustedThirdParty) public {
        owner = msg.sender;
        balances[owner] = 200000 * 10**uint(_decimals);                     // for R&D purposes, you know
        availableSupply -= 200000 * 10**uint(_decimals);
        trustedThirdParty = _trustedThirdParty;
    }

    // Very secure
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Very trusted
    modifier onlyTrustedThirdParty {
        require(msg.sender == trustedThirdParty); // trusted third party is very trusted
        _;
    }

    function name() public pure returns (string) {
        return (_name);
    }

    function symbol() public pure returns (string) {
        return (_symbol);
    }

    function totalSupply() public pure returns (uint256) {
        return (_totalSupply);
    }

    function decimals() public pure returns (uint8) {
        return (_decimals);
    }

    // Money trap
    function deposit() public payable {
        require(deposited + msg.value > deposited);
        require(balances[msg.sender] + msg.value > balances[msg.sender]); // check for overflows
        require(msg.value * tokenRate < availableSupply);
        availableSupply -= msg.value * tokenRate;
        balances[msg.sender] += msg.value * tokenRate;
        deposited += msg.value;
    }

    // Token balances
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    // Token transfer
    function transfer(address _to, uint _value) public {
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value > balances[_to]); // Check for overflows
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }

    // Money withdraw
    function withdraw(uint amount) public onlyTrustedThirdParty { // Only the trusted third party can withdraw the money, uh... I guess
        require(amount <= deposited);
        deposited -= amount;
        msg.sender.transfer(amount);
    }

    // Entangle quantic cloud IOT data in quantic blockchain big-data
    function entangleQuanticCloudIOTData(uint IOTData) public {
        quanticBlockchainBigData.push(IOTData);
    }

    // Detangle quantic cloud IOT data from quantic blockchain big-data
    function detangleQuanticCloudIOTData() public {
        require(quanticBlockchainBigData.length >= 0);
        quanticBlockchainBigData.length--;
    }

    // Modify quantic blockchain big-data
    function modifyQuanticCloudIOTData(uint index, uint IOTData) public {
        require(index < quanticBlockchainBigData.length);
        quanticBlockchainBigData[index] = IOTData;
    }

    // In case of anything bad happens, only callable by trusted third party
    function killItWithFire() public onlyTrustedThirdParty {
        selfdestruct(owner);
    }
}