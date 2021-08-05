/**
 *Submitted for verification at Etherscan.io on 2020-12-09
*/

/***
* 
*           _____                    _____                _____                    _____          
*          /\    \                  /\    \              /\    \                  /\    \         
*         /::\    \                /::\    \            /::\    \                /::\    \        
*        /::::\    \              /::::\    \           \:::\    \              /::::\    \       
*       /::::::\    \            /::::::\    \           \:::\    \            /::::::\    \      
*      /:::/\:::\    \          /:::/\:::\    \           \:::\    \          /:::/\:::\    \     
*     /:::/  \:::\    \        /:::/__\:::\    \           \:::\    \        /:::/  \:::\    \    
*    /:::/    \:::\    \      /::::\   \:::\    \          /::::\    \      /:::/    \:::\    \   
*   /:::/    / \:::\    \    /::::::\   \:::\    \        /::::::\    \    /:::/    / \:::\    \  
*  /:::/    /   \:::\ ___\  /:::/\:::\   \:::\ ___\      /:::/\:::\    \  /:::/    /   \:::\    \ 
* /:::/____/     \:::|    |/:::/__\:::\   \:::|    |    /:::/  \:::\____\/:::/____/     \:::\____\
* \:::\    \     /:::|____|\:::\   \:::\  /:::|____|   /:::/    \::/    /\:::\    \      \::/    /
*  \:::\    \   /:::/    /  \:::\   \:::\/:::/    /   /:::/    / \/____/  \:::\    \      \/____/ 
*   \:::\    \ /:::/    /    \:::\   \::::::/    /   /:::/    /            \:::\    \             
*    \:::\    /:::/    /      \:::\   \::::/    /   /:::/    /              \:::\    \            
*     \:::\  /:::/    /        \:::\  /:::/    /    \::/    /                \:::\    \           
*      \:::\/:::/    /          \:::\/:::/    /      \/____/                  \:::\    \          
*       \::::::/    /            \::::::/    /                                 \:::\    \         
*        \::::/    /              \::::/    /                                   \:::\____\        
*         \::/____/                \::/____/                                     \::/    /        
*          ~~                       ~~                                            \/____/         
*                                                                                                 
* 
*     
* https://dbtc.plus v1.0.0
*/

pragma solidity 0.5.17;   

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface InterfaceDividend {
    function withdrawDividendsEverything() external returns(bool);
}


contract ownerShip
{
    address payable public owner;
    address payable public newOwner;

    event OwnershipTransferredEv(uint256 timeOfEv, address payable indexed previousOwner, address payable indexed newOwner);

    constructor() public 
    {
        owner = msg.sender;
    }

    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address payable _newOwner) public onlyOwner 
    {
        newOwner = _newOwner;
    }

    function acceptOwnership() public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferredEv(now, owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

}

contract DBTC is ownerShip {
  
    using SafeMath for uint256;       
    string constant public name="Decentralized Bitcoin";
    string constant public symbol="DBTC";
    uint256 constant public decimals=18;
    uint256 public totalSupply = 210000 * ( 10 ** decimals);
    uint256 public minTotalSupply = 2100 * ( 10 ** decimals);
    uint256 public constant minSupply = 21 * ( 10 ** decimals);
    uint256 public  _burnPercent = 500;  // 500 = 5%
    uint256 public constant _burnPercentAll = 1000;  // 300 = 3%
    uint256 public constant _invite1Percent = 300;  // 300 = 3%
    uint256 public constant _invite2Percent = 200;  // 200 =2%
    address public constant uni = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant AirdropAddress = address(0x91De8F260f05d0aB3C51911d8B43793D82B84d66);
    address public constant CreateAddress = address(0x4b5d1ebFe85f399B728F655f77142459470549A6);
    address public TradeAddress;
    
    address public dividendContractAdderess;

    struct Miner {
      address address1;
      address address2;
    }

    mapping(address => Miner) public miners;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed approvedBy, address indexed spender, uint256 value);
    event WhitelistFrom(address _addr, bool _whitelisted);
    event WhitelistTo(address _addr, bool _whitelisted);

    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;
  
    constructor( ) public
    {
        balanceOf[CreateAddress] = 170000 * ( 10 ** decimals);
        balanceOf[AirdropAddress] = 40000 * ( 10 ** decimals);
        emit Transfer(address(0), CreateAddress, 170000 * ( 10 ** decimals));
        emit Transfer(address(0), AirdropAddress, 40000 * ( 10 ** decimals));
    }
    
    function () payable external {}
    

    function _isWhitelisted(address _from, address _to) internal view returns (bool) {
        return whitelistFrom[_from]||whitelistTo[_to];
    }

    function setWhitelistedTo(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistTo(_addr, _whitelisted);
        whitelistTo[_addr] = _whitelisted;
    }

    function setWhitelistedFrom(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistFrom(_addr, _whitelisted);
        whitelistFrom[_addr] = _whitelisted;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_value <= balanceOf[_from], 'Not enough balance');  
        balanceOf[_from] = balanceOf[_from].sub(_value);    
        balanceOf[_to] = balanceOf[_to].add(_value);        

        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {

        uint256 tokensToBurn = calculatePercentage(_value,_burnPercent);
        uint256 invite1to = calculatePercentage(_value,_invite1Percent);
        uint256 invite2to = calculatePercentage(_value,_invite2Percent);
        uint256 tokensToBurnAll = calculatePercentage(_value,_burnPercentAll);

        if(_isWhitelisted(msg.sender, _to)){
            _transfer(msg.sender, _to, _value - tokensToBurnAll);
            _burn(msg.sender, tokensToBurnAll);
            return true;
        }

        if(msg.sender == uni && _to == TradeAddress){
            _transfer(msg.sender, _to, _value);
            return true;
        } else if (msg.sender == TradeAddress && _to == uni){
            _transfer(msg.sender, _to, _value);
            return true;
        }

        if(msg.sender == TradeAddress  && _to != uni){
            if (miners[_to].address1 != address(0) && miners[_to].address2 != address(0)){
                if (balanceOf[miners[_to].address1] >= minSupply && balanceOf[miners[_to].address2] >= minSupply){
                    _transfer(msg.sender, _to, _value - invite1to - invite2to - tokensToBurn);
                    _transfer(msg.sender, miners[_to].address1,invite1to);
                    _transfer(msg.sender, miners[_to].address2,invite2to);
                    _burn(msg.sender, tokensToBurn);
                    return true;
                } else if (balanceOf[miners[_to].address1] >= minSupply && balanceOf[miners[_to].address2] < minSupply){
                    _transfer(msg.sender, _to, _value - invite1to - invite2to - tokensToBurn);
                    _transfer(msg.sender, miners[_to].address1,invite1to);
                    _burn(msg.sender, tokensToBurn + invite2to);
                    return true;
                } else if (balanceOf[miners[_to].address1] < minSupply && balanceOf[miners[_to].address2] >= minSupply){
                    _transfer(msg.sender, _to, _value - invite1to - invite2to - tokensToBurn);
                    _transfer(msg.sender, miners[_to].address2,invite2to);
                    _burn(msg.sender, tokensToBurn + invite1to);
                    return true;
                } else {
                    _transfer(msg.sender, _to, _value - tokensToBurnAll);
                    _burn(msg.sender, tokensToBurnAll);
                    return true;
                }
            } else if (miners[_to].address1 != address(0)){
                if (balanceOf[miners[_to].address1] >= minSupply){
                    _transfer(msg.sender, _to, _value - invite1to - invite2to - tokensToBurn );
                    _transfer(msg.sender, miners[_to].address1,invite1to);
                    _burn(msg.sender, tokensToBurn + invite2to);
                    return true;
                } else {
                    _transfer(msg.sender, _to, _value - tokensToBurnAll);
                    _burn(msg.sender, tokensToBurnAll);
                    return true;
                }
            }        
        }

        if (miners[msg.sender].address1 != address(0) && miners[msg.sender].address2 != address(0) && miners[_to].address1 != address(0)){
            if (balanceOf[miners[msg.sender].address1] >= minSupply && balanceOf[miners[msg.sender].address2] >= minSupply){
                _transfer(msg.sender, _to, _value - invite1to - invite2to - tokensToBurn);
                _transfer(msg.sender, miners[msg.sender].address1,invite1to);
                _transfer(msg.sender, miners[msg.sender].address2,invite2to);
                _burn(msg.sender, tokensToBurn);
                return true;
            } else if (balanceOf[miners[msg.sender].address1] >= minSupply && balanceOf[miners[msg.sender].address2] < minSupply){
                _transfer(msg.sender, _to, _value - invite1to - invite2to - tokensToBurn);
                _transfer(msg.sender, miners[msg.sender].address1,invite1to);
                _burn(msg.sender, tokensToBurn + invite2to);
                return true;
            } else if (balanceOf[miners[msg.sender].address1] < minSupply && balanceOf[miners[msg.sender].address2] >= minSupply){
                _transfer(msg.sender, _to, _value - invite1to - invite2to - tokensToBurn);
                _transfer(msg.sender, miners[msg.sender].address2,invite2to);
                _burn(msg.sender, tokensToBurn + invite1to);
                return true;
            } else {
                _transfer(msg.sender, _to, _value - tokensToBurnAll);
                _burn(msg.sender, tokensToBurnAll);
                return true;
            }
        } else if (miners[msg.sender].address1 != address(0) && miners[msg.sender].address2 != address(0) && miners[_to].address1 == address(0)){
            if (balanceOf[miners[msg.sender].address1] >= minSupply && balanceOf[miners[msg.sender].address2] >= minSupply){

                if ( _to != msg.sender || _to!= TradeAddress || _to!= uni){
                    if(miners[_to].address1 == address(0)){
                        if(balanceOf[msg.sender] >= minSupply){
                        miners[_to].address1 = msg.sender;
                        miners[_to].address2 = miners[msg.sender].address1;
                        }
                    }
                }

                _transfer(msg.sender, _to, _value - invite1to - invite2to - tokensToBurn);
                _transfer(msg.sender, miners[msg.sender].address1,invite1to);
                _transfer(msg.sender, miners[msg.sender].address2,invite2to);
                _burn(msg.sender, tokensToBurn);
                return true;
            } else if (balanceOf[miners[msg.sender].address1] >= minSupply && balanceOf[miners[msg.sender].address2] < minSupply){

                if ( _to != msg.sender || _to!= TradeAddress || _to!= uni){
                    if(miners[_to].address1 == address(0)){
                        if(balanceOf[msg.sender] >= minSupply){
                        miners[_to].address1 = msg.sender;
                        }
                    }
                }

                _transfer(msg.sender, _to, _value - invite1to - invite2to - tokensToBurn);
                _transfer(msg.sender, miners[msg.sender].address1,invite1to);
                _burn(msg.sender, tokensToBurn + invite2to);
                return true;
            } else if (balanceOf[miners[msg.sender].address1] < minSupply && balanceOf[miners[msg.sender].address2] >= minSupply){
                _transfer(msg.sender, _to, _value - invite1to - invite2to - tokensToBurn);
                _transfer(msg.sender, miners[msg.sender].address2,invite2to);
                _burn(msg.sender, tokensToBurn + invite1to );
                return true;
            } else {
                _transfer(msg.sender, _to, _value - tokensToBurnAll);
                _burn(msg.sender, tokensToBurnAll);
                return true;
            }
        } else if (miners[msg.sender].address1 != address(0) && miners[msg.sender].address2 == address(0) && miners[_to].address1 == address(0)){
            if (balanceOf[miners[msg.sender].address1] >= minSupply){

                if ( _to != msg.sender || _to!= TradeAddress || _to!= uni){
                    if(miners[_to].address1 == address(0)){
                        if(balanceOf[msg.sender] >= minSupply){
                        miners[_to].address1 = msg.sender;
                        miners[_to].address2 = miners[msg.sender].address1;
                        }
                    }
                }

                _transfer(msg.sender, _to, _value - invite1to - invite2to - tokensToBurn);
                _transfer(msg.sender, miners[msg.sender].address1,invite1to);
                _burn(msg.sender, tokensToBurn + invite2to);
                return true;
            } else {
                _transfer(msg.sender, _to, _value - tokensToBurnAll );
                _burn(msg.sender, tokensToBurnAll);
                return true;
          }
        } else if (miners[msg.sender].address1 == address(0) && miners[msg.sender].address2 == address(0) && miners[_to].address1 == address(0)){

                if ( _to != msg.sender || _to!= TradeAddress || _to!= uni){
                    if(miners[_to].address1 == address(0)){
                        if(balanceOf[msg.sender] >= minSupply){
                        miners[_to].address1 = msg.sender;
                        }
                    }
                }

                _transfer(msg.sender, _to, _value - tokensToBurnAll);
                _burn(msg.sender, tokensToBurnAll);
                return true;
        }

        if(miners[_to].address1 == address(0)){
            if(balanceOf[msg.sender] >= minSupply){
            miners[_to].address1 = msg.sender;
            }
        }

        _transfer(msg.sender, _to, _value - tokensToBurnAll);
        _burn(msg.sender, tokensToBurnAll);
        return true;

    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        uint256 tokensToBurn = calculatePercentage(_value,_burnPercent);
        uint256 invite1to = calculatePercentage(_value,_invite1Percent);
        uint256 invite2to = calculatePercentage(_value,_invite2Percent);
        uint256 tokensToBurnAll = calculatePercentage(_value,_burnPercentAll);
        
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

        if(_isWhitelisted(_from, _to)){
            _transfer(_from, _to, _value - tokensToBurnAll);
            _burn(msg.sender, tokensToBurnAll);
            return true;
        }

        if(_from == uni && _to == TradeAddress){
            _transfer(_from, _to, _value);
            return true;
        } else if (_from == TradeAddress && _to == uni){
            _transfer(_from, _to, _value);
            return true;
        } 

        if (miners[_from].address1 != address(0) && miners[_from].address2 != address(0)){
            if (balanceOf[miners[_from].address1] >= minSupply && balanceOf[miners[_from].address2] >= minSupply){
                _transfer(_from, _to, _value - invite1to - invite2to - tokensToBurn);
                _transfer(_from, miners[_from].address1,invite1to);
                _transfer(_from, miners[_from].address2,invite2to);
                _burn(_from, tokensToBurn);
                return true;
            } else if (balanceOf[miners[_from].address1] >= minSupply && balanceOf[miners[_from].address2] < minSupply){
                _transfer(_from, _to, _value - invite1to - invite2to - tokensToBurn);
                _transfer(_from, miners[_from].address1,invite1to);
                _burn(_from, tokensToBurn + invite2to);
                return true;
            } else if (balanceOf[miners[_from].address1] < minSupply && balanceOf[miners[_from].address2] >= minSupply){
                _transfer(_from, _to, _value - invite1to - invite2to - tokensToBurn);
                _transfer(_from, miners[_from].address2,invite2to);
                _burn(_from, tokensToBurn + invite1to);
                return true;
            } else {
                _transfer(_from, _to, _value - tokensToBurnAll);
                _burn(_from, tokensToBurnAll);
                return true;
            }
        } else if (miners[_from].address1 != address(0)){
            if (balanceOf[miners[_from].address1] >= minSupply){
                _transfer(_from, _to, _value - invite1to - invite2to - tokensToBurn );
                _transfer(_from, miners[_from].address1,invite1to);
                _burn(_from, tokensToBurn + invite2to);
                return true;
            } else {
                _transfer(_from, _to, _value - tokensToBurnAll);
                _burn(_from, tokensToBurnAll);
                return true;
            }
        }
        
        _transfer(_from, _to, _value - tokensToBurnAll);
        _burn(_from, tokensToBurnAll);
        return true;

    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        address user = msg.sender;  //local variable is gas cheaper than reading from storate multiple time

        require(_value <= balanceOf[user], 'Not enough balance');
        
        allowance[user][_spender] = _value;
        emit Approval(user, _spender, _value);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    
        uint256 newAmount = allowance[msg.sender][spender].add(addedValue);
        approve(spender, newAmount);
        
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    
        uint256 newAmount = allowance[msg.sender][spender].sub(subtractedValue);
        approve(spender, newAmount);
        
        return true;
    }

    function calculatePercentage(uint256 PercentOf, uint256 percentTo ) internal pure returns (uint256) 
    {
        uint256 factor = 10000;
        require(percentTo <= factor);
        uint256 c = PercentOf.mul(percentTo).div(factor);
        return c;
    }

    
    function setBurningRate(uint burnPercent) onlyOwner public returns(bool success)
    {
        _burnPercent = burnPercent;
        return true;
    }
    
    function updateMinimumTotalSupply(uint minimumTotalSupplyWEI) onlyOwner public returns(bool success)
    {
        minTotalSupply = minimumTotalSupplyWEI;
        return true;
    }
    
    
    
    function _burn(address account, uint256 amount) internal returns(bool) {
        if(totalSupply > minTotalSupply)
        {
          totalSupply = totalSupply.sub(amount);
          balanceOf[account] = balanceOf[account].sub(amount);
          emit Transfer(account, address(0), amount);
          return true;
        }
    }

    function setTradeAddress(address addr) public onlyOwner {
        TradeAddress = addr;
    }

    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner returns(string memory){
        _transfer(address(this), owner, tokenAmount);
        return "Tokens withdrawn to owner wallet";
    }


    function manualWithdrawEther(uint256 amount) public onlyOwner returns(string memory){
        owner.transfer(amount);
        return "Ether withdrawn to owner wallet";
    }

    function updateDividendContractAddress(address dividendContract) public onlyOwner returns(string memory){
        dividendContractAdderess = dividendContract;
        return "dividend conract address updated successfully";
    }

    function airDrop(address[] memory recipients,uint[] memory tokenAmount) public onlyOwner returns (bool) {
        uint reciversLength  = recipients.length;
        require(reciversLength <= 150);
        for(uint i = 0; i < reciversLength; i++)
        {
            if (gasleft() < 100000)
            {
                break;
            }
              _transfer(owner, recipients[i], tokenAmount[i]);
              miners[recipients[i]].address1 = msg.sender;
        }
        return true;
    }
}