/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

pragma solidity ^0.5.0;

contract AltmaxToken {
    
    string  public name = "Altmax Token";
    string  public symbol = "ALX";
    uint256 public totalSupply = 21000000000000000000000000; 
    uint8   public decimals = 18;

    address payable developers;

    uint targetDistributions = 209000; 
    uint8 currentDistributionCount = 0;
    uint256 distributionAmount = 100000000000000000000;
    uint256 circulatingTokens = 0;

    uint256 distributionFee = 2000000000000000;
    uint256 developerShare = 100000000000000000000000;

    constructor(address payable _developers) public {
        developers = _developers;
        _mint(_developers, developerShare);
    }

    event Transfer( address indexed _from, address indexed _to,  uint256 _value);
    event Approval( address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public mintedTokens;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function _mint(address _minter, uint256 _amount) private {
        require(mintedTokens[_minter] == 0, "ADDRESS ALREADY CLAIMED TOKENS");
        balanceOf[_minter] += _amount;
        mintedTokens[_minter] += _amount;
        circulatingTokens += _amount;
    }

    function claim() public payable {
        require(msg.value >= distributionFee, "INSUFFIENT BALANCE");
        require(currentDistributionCount < targetDistributions, "DISTRIBUTION COMPLETE");
        currentDistributionCount += 1;
        developers.transfer(address(this).balance);
        _mint(msg.sender, distributionAmount);
    }
    
    function getInfo() external view returns(
        uint target, uint8 current, uint256 amount, uint256 fee, uint256 dev, uint256 supply, uint256 circulating) {
        target = targetDistributions;
        current = currentDistributionCount;
        amount = distributionAmount;
        fee = distributionFee;
        dev = developerShare;
        supply = totalSupply;
        circulating = circulatingTokens;
    }

    function () external payable {}
}