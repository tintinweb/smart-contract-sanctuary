/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ROSETokenContract {
    using SafeMath for uint256;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => uint) public frozen_address;
    uint public totalSupply = 1000000000 * 10 ** 18;
    uint public supplyStake = 90000000 * 10 ** 18; 
    string public name = "Rose";
    string public symbol = "ROSE";
    uint public decimals = 18;

    address public contract_owner;
    uint256 public marketingFeePercentage = 0;
    uint256 public economyFeePercentage = 0;
    address public marketingWallet = 0xa623367488D1422C2236BcF01556F0c2Bb1E9012;
    address public economyWallet = 0x626fd179Faf192e8b4AB89b6602ce9f75daA84D2;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
       constructor() {
        contract_owner = 0x237B2337f01c49390B6216301b09C17177D845ED;
        balances[0x237B2337f01c49390B6216301b09C17177D845ED] = totalSupply.sub(supplyStake);
        balances[0x3896f3d649594Fe42fE54486f69C08ECaDb5a992] = supplyStake;
        frozen_address[0x3896f3d649594Fe42fE54486f69C08ECaDb5a992] = block.timestamp.add(1643378959);

       }   
    function modifyMarketingFeePercentage(uint256 _newVal) external onlyOwner {
    require(_newVal <20,"can not set fee percentage higher then 20");
    marketingFeePercentage = _newVal;
    }  

    function modifyEconomyFeePercentage(uint256 _newVal) external onlyOwner {
        require(_newVal <20,"can not set fee percentage higher then 20");
        economyFeePercentage = _newVal;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function getMarketingFee(uint256 _value) public view returns(uint256){
        uint256 marketingFee = (marketingFeePercentage.mul(_value)).div(100);
        return(marketingFee);
    }
    function getEconomyFee(uint256 _value) public view returns(uint256){
        uint256 economyFee = (economyFeePercentage.mul(_value)).div(100);
        return(economyFee);
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(frozen_address[msg.sender] < block.timestamp, 'this address is frozen now'); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        
        balances[marketingWallet] += getMarketingFee(value);
        balances[economyWallet] += getEconomyFee(value);
        balances[to] += value.sub(getMarketingFee(value).add(getEconomyFee(value)));
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(frozen_address[from] < block.timestamp, 'this address is frozen now'); 
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');

        balances[marketingWallet] += getMarketingFee(value);
        balances[economyWallet] += getEconomyFee(value);
        balances[to] += value.sub(getMarketingFee(value).add(getEconomyFee(value)));
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

    modifier onlyOwner() {
        require(msg.sender==contract_owner, "Only contract owner can do this");
        _;
    }
}