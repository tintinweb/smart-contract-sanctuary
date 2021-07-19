//SourceUnit: safeMath.sol

pragma solidity >=0.4.22 <0.7.0;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


//SourceUnit: starToken.sol

pragma solidity ^0.4.24;
import "./safeMath.sol";

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract Star {
    using SafeMath for uint256;
    string public name = "IPFstar";
    string public symbol = "STAR";
    uint8 public decimals = 6; 
    uint256 public totalSupply;
    uint256 public totalValue;  
    uint8 public valueDecimals = 6;  
    address owner = msg.sender;
    address admin;
    uint public produceBalance;  
    uint public bureBalance; 

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);  
    event Burn(address indexed from, uint256 value);  

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }



    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from]  = balanceOf[_from].sub(_value);
        uint fee = _value.mul(10).div(100);
        balanceOf[_to] = balanceOf[_to].add(_value.sub(fee)); 

        bureBalance = bureBalance.add(fee);  

        totalSupply = totalSupply.sub(fee) ;
        emit Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] + fee == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); 
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

 
    function _bure(address _target,uint256 _value) internal{
        require(balanceOf[_target] >= _value); 
        balanceOf[_target] = balanceOf[_target].sub(_value);          
        totalSupply = totalSupply.sub(_value);        
        bureBalance = bureBalance.add(_value);           
        emit Burn(_target, _value);
    }

    function burn(uint256 _value) public returns (bool success) {
        _bure(msg.sender,_value);
        return true;
    }
 
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);              
        require(_value <= allowance[_from][msg.sender]);  
        balanceOf[_from] = balanceOf[_from].sub(_value);                       
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);           
        totalSupply = totalSupply.sub(_value);                            
        emit Burn(_from, _value);
        return true;
    }

 
    function _mintToken(address target,uint256 mintedAmount) internal {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }

    function mintToken(address target, uint256 mintedAmount) public onlyAdmin {
       _mintToken(target,mintedAmount);
    }

  
    function setAdmin(address _address) public onlyOwner{
        admin = _address;
    }

 
    function getPrice() public view returns (uint){
        uint initPrice = 1125 * 10 ** uint256(valueDecimals-4);
        
        if(totalSupply == 0){
            return initPrice;
        }

        if(totalValue == 0){
            return initPrice;
        }

    
        return totalValue.div(totalSupply.div(10**uint256(decimals)));
    }

 
    function buy(address _buyer,uint _balance,uint _totalValue) public onlyAdmin{
        totalValue = totalValue.add(_totalValue); 
        uint _allBalance = _balance;
        _balance = _balance.mul(90).div(100);  
        uint _fee = _allBalance.sub(_balance);
        produceBalance = produceBalance.add(_allBalance); 
        bureBalance = bureBalance.add(_fee);  

        _mintToken(_buyer,_balance);
    }


    function sell(address _seller,uint _balance,uint _totalValue) public onlyAdmin{
        _totalValue = _totalValue.mul(90).div(100);  
        totalValue = totalValue.sub(_totalValue);  

        _bure(_seller,_balance); 
    }


    function trans(address _from_address,address _to_address,uint _balance) public onlyAdmin{
        require(_to_address != 0x0);
        require(balanceOf[_from_address] >= _balance);
        require(balanceOf[_to_address] + _balance >= balanceOf[_to_address]);
        uint previousBalances = balanceOf[_from_address].add(balanceOf[_to_address]);
        balanceOf[_from_address] = balanceOf[_from_address].sub(_balance);
        balanceOf[_to_address] = balanceOf[_to_address].add(_balance); 
        emit Transfer(_from_address, _to_address, _balance);

        assert(balanceOf[_from_address] + balanceOf[_to_address] == previousBalances);
    }

}