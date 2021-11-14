/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

pragma solidity ^0.5.0;

    //interfaces
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 _value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed _from, uint _value);
}

contract my_coin is IERC20{
    //constants
    string public name;
    string  public symbol;
    uint256 public totalSupply;//6 billion coins
    uint8   public decimals;
    address public charity_wallet;
    address public tax_wallet;
    address public marketing_wallet;
    
    address[] public users;
    mapping(address => bool) public isUser;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint8 public feeRate;
    uint8 public liquidityFee;
    uint8 public charity;
    uint8 public tax;
    uint8 public redistribution;
    uint8 public marketing;
    uint8 public burnRate;
    uint256 public feeTotal;
    uint256 public liquidityTotal;
    
    //constructor
    constructor() public {
        name="My Coin";
        symbol="myCOIN";
        totalSupply = 6000000000*10**18;
        decimals = 18;
        
        feeRate=25;
        liquidityFee=15;
        charity=10;
        tax=20;
        redistribution=35;
        marketing=20;
        burnRate=15;
        feeTotal=0;
        liquidityTotal=0;
        
        charity_wallet=0x5b59cA3ca4121E42e5550F76546E22a712491cBc;
        tax_wallet=0xe5a014d8c62213830F2dbE5660D5B22912D6a21e;
        marketing_wallet=0x04e8Bbe7159b9637505A6e408BD6Ae24b920Fc16;
        
        
        balanceOf[tax_wallet] = totalSupply;
        users.push(charity_wallet);
        users.push(tax_wallet);
        users.push(marketing_wallet);
        isUser[charity_wallet]=true;
        isUser[tax_wallet]=true;
        isUser[marketing_wallet]=true;
    }
    
    //functions
    function transfer(address _to, uint256 _value) public returns (bool){
        if(msg.sender==tax_wallet){
            bool takeFee=false;
            _tokenTransfer(_to, _value, takeFee);
            return true;
        }
        else if(msg.sender==marketing_wallet){
            bool takeFee=false;
            _tokenTransfer(_to, _value, takeFee);
            return true;
        }
        else if(msg.sender==charity_wallet){
            bool takeFee=false;
            _tokenTransfer(_to, _value, takeFee);
            return true;
        }
        else if(msg.sender==address(this)){
            bool takeFee=false;
            _tokenTransfer(_to, _value, takeFee);
            return true;
        }
        else{
            bool takeFee=true;
            _tokenTransfer(_to, _value, takeFee);
            return true;
        }
    }
    function burn(uint256 _value) public returns (bool){
        require(balanceOf[msg.sender] >= _value);
        require(msg.sender==tax_wallet);
        balanceOf[tax_wallet]-=_value;
        totalSupply-=_value;
        emit Burn(tax_wallet,_value);
        return true;
    }
    function supply() public view returns (uint256){
        return totalSupply;
    }
    function approve(address _spender, uint256 _value) public returns (bool){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        if(msg.sender==tax_wallet){
            bool takeFee=false;
            _tokenTransfer(_to, _value, takeFee);
            allowance[msg.sender][_from] -= _value;
            return true;
        }
        else if(msg.sender==marketing_wallet){
            bool takeFee=false;
            _tokenTransfer(_to, _value, takeFee);
            allowance[msg.sender][_from] -= _value;
            return true;
        }
        else if(msg.sender==charity_wallet){
            bool takeFee=false;
            _tokenTransfer(_to, _value, takeFee);
            allowance[msg.sender][_from] -= _value;
            return true;
        }
        else if(msg.sender==address(this)){
            bool takeFee=false;
            _tokenTransfer(_to, _value, takeFee);
            return true;
        }
        else{
            bool takeFee=true;
            _tokenTransfer(_to, _value, takeFee);
            allowance[msg.sender][_from] -= _value;
            return true;
        }
    }
    function _calculateTaxFee(uint256 _amount) private returns (uint256){
        return (_amount*feeRate)/1000;
    }
    function _calculateLiquidityFee(uint256 _amount) private returns (uint256){
        return (_amount*liquidityFee)/1000;
    }
    function _redistribute(uint256 _amount) private returns (bool){
        uint256 redist=_amount*redistribution/100;
        uint256 andel;
        for (uint i=0; i<users.length; i++) {
            andel=100000000000000000000*balanceOf[users[i]]/totalSupply;
            balanceOf[users[i]]+=andel*redist/100000000000000000000;
        }
        balanceOf[charity_wallet]+=_amount*charity/100;
        balanceOf[tax_wallet]+=_amount*tax/100;
        balanceOf[marketing_wallet]+=_amount*marketing/100;
        totalSupply-=_amount*burnRate/100;
        uint256 allAccounts=0;
        uint256 difference=0;
        for (uint i=0; i<users.length; i++) {
            allAccounts+=balanceOf[users[i]];
        }
        difference=totalSupply-allAccounts;
        balanceOf[tax_wallet]+=difference;
        return true;
    }
    function _tokenTransfer(address _to, uint256 _value, bool takeFee) private returns (bool){
        require(balanceOf[msg.sender] >= _value);
        if(!isUser[_to]) {
            users.push(_to);
            isUser[_to]=true;
        }
        if (!takeFee){
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        else{
            (uint256 TransferAmount,uint256 fee, uint256 liquidity)=_getValues(_value);
            _redistribute(fee);
            _takeLiquidity(liquidity);
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] +=TransferAmount;
            _reflectFee(fee);
            _reflectLiquidity(liquidity);
            emit Transfer(msg.sender, _to, TransferAmount);
            return true;
        }
    }
    function _getValues(uint256 _amount) private returns (uint256, uint256, uint256){
        uint256 tFee=_calculateTaxFee(_amount);
        uint256 tLiquid=_calculateLiquidityFee(_amount);
        uint256 tTransferAmount = _amount - (tFee+tLiquid);
        return (tTransferAmount, tFee, tLiquid);
    }
    function _takeLiquidity(uint256 _amount) private {
        balanceOf[address(this)] += _amount;
    }
    function _reflectFee(uint256 fee) private{
        feeTotal+=fee;
    }
    function _reflectLiquidity(uint256 liquidity) private {
        liquidityTotal+=liquidity;
    }
}